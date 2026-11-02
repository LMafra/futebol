# Methods rather than constants: db/seeds.rb `load`s this file on every run, and constants would be redefined.
module Seeds
  def self.demo_password = 'demo-futebol'

  # Rounds 1-4 and 6 end scored, 5 is live, 7-10 stay scheduled. Predictions go in before the matches close,
  # so the scoring job finds them.
  def self.demo(championship)
    users = demo_users
    pool = demo_pool(championship, users)
    demo_predictions(pool, championship, users)
    demo_results(championship)
    demo_upcoming_dates(championship)
    demo_lineup(users.first, championship)
  end

  # Signup público disponível em /signup; estas contas existem só para a demo local.
  def self.demo_users
    (1..5).map do |number|
      Core::User.find_or_create_by!(email_address: "demo#{number}@demo.local") do |user|
        user.name = "Demo #{number}"
        user.password = demo_password
      end
    end
  end

  def self.demo_pool(championship, users)
    pool = Bolao::Pool.find_or_create_by!(code: 'DEMO01') do |new_pool|
      new_pool.assign_attributes(name: 'Bolão Demo', championship:, owner: users.first)
    end
    users.each { |user| pool.memberships.find_or_create_by!(user:) }
    pool
  end

  def self.demo_predictions(pool, championship, users)
    (1..10).each do |round|
      demo_round(championship, round).first(3).each_with_index do |match, index|
        users.each.with_index(1) do |user, number|
          prediction = Bolao::Prediction.kept.find_or_initialize_by(pool:, user:, match:)
          next if prediction.persisted?

          prediction.home_guess, prediction.away_guess = demo_guess(number, round, index)
          prediction.save!(context: :backfill)
        end
      end
    end
  end

  def self.demo_results(championship)
    [1, 2, 3, 4, 6].each do |round|
      demo_round(championship, round).each_with_index do |match, index|
        demo_finish(match, *demo_score(round, index))
        ProcessMatchPointsJob.perform_now(match.id, demo_scoring_token(match))
      end
    end
    demo_round(championship, 5).each { |match| match.start_match! if match.may_start_match? }
  end

  def self.demo_finish(match, home_score, away_score)
    return unless match.scheduled? || match.live?

    match.assign_attributes(home_score:, away_score:)
    match.start_match! if match.may_start_match?
    match.finish_match!
  end

  # Seed dates start in April 2026, so rounds 7-10 would already be past for the betting countdown.
  # They shift by the same whole number of weeks: same weekday and kickoff, still one week apart.
  def self.demo_upcoming_dates(championship)
    matches = (7..10).flat_map { |round| demo_round(championship, round).select(&:scheduled?) }
    return if matches.all? { |match| match.match_date.future? }

    shift = weeks_until_future(matches.map(&:match_date).min)
    matches.each { |match| match.update!(match_date: match.match_date + shift) }
  end

  def self.weeks_until_future(time) = (((Time.current - time) / 1.week).floor + 1).weeks

  # Bought through the wallet, so the demo user's balance reflects it.
  def self.demo_lineup(user, championship)
    squad = Cartola::Squad.find_or_create_by!(user:) { |new_squad| new_squad.name = "Time de #{user.name}" }
    lineup = squad.lineups.find_or_initialize_by(championship:, round: 7)
    return if lineup.persisted?

    lineup.formation = '4-3-3'
    assign_demo_players(lineup)
    Cartola::WalletService.save(lineup) || raise("demo lineup: #{lineup.errors.full_messages.to_sentence}")
  end

  def self.assign_demo_players(lineup)
    players = demo_lineup_players
    lineup.assign_players(players)
    lineup.assign_captain(players.last&.id)
  end

  # The cheapest players per position, up to the championship's default limits (1 / 2 / 3 / 3).
  def self.demo_lineup_players
    { 'GOL' => 1, 'LAT' => 1, 'ZAG' => 1, 'MEI' => 3, 'ATA' => 3 }.flat_map do |position, count|
      Core::Player.where(position:).order(:base_value, :external_id).first(count)
    end
  end

  def self.demo_round(championship, round)
    championship.matches.where(round:).order(:external_id)
  end

  def self.demo_score(round, index) = [(round + index) % 4, (round + (2 * index)) % 3]

  # Rotates exact score, right goal difference, swapped score and a near miss across users and matches.
  def self.demo_guess(user_number, round, index)
    home, away = demo_score(round, index)
    case (user_number + round + index) % 4
    when 0 then [home, away]
    when 1 then [home + 1, away + 1]
    when 2 then [away, home]
    else [home + 1, away]
    end
  end

  # Fixed per match: on a second load the job gets the token it already stamped and returns early.
  def self.demo_scoring_token(match)
    Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "futebol-demo:#{match.external_id}")
  end
end
