# Methods rather than constants: db/seeds.rb `load`s this file on every run, and constants would be redefined.
module Seeds
  def self.demo_password = 'demo-futebol'

  # Rounds 1-4 and 6 end scored, 5 is live, 7-10 stay scheduled. Predictions go in before the matches close,
  # so the scoring job finds them. demo1 has the upcoming round 7 lineup; the others fill round 6's Esquadrão.
  def self.demo(championship)
    users = demo_users
    pool = demo_pool(championship, users)
    demo_predictions(pool, championship, users)
    demo_results(championship)
    demo_upcoming_dates(championship)
    demo_lineup(users.first, championship)
    users.drop(1).each.with_index(2) { |user, number| demo_lineup(user, championship, round: 6, pick: number) }
  end

  # Signup público disponível em /signup; estas contas existem só para a demo local.
  # demo1-3 consent to a public profile, so the rankings show both their names and "Participante".
  def self.demo_users
    demo_names.each.with_index(1).map do |name, number|
      user = Core::User.find_or_create_by!(email_address: "demo#{number}@demo.local") do |new_user|
        new_user.assign_attributes(name:, password: demo_password)
      end
      demo_profile(user, name, number)
    end
  end

  # Databases seeded before the names and consent catch up; a name changed in /minha-conta stays.
  def self.demo_profile(user, name, number)
    user.name = name if user.name == "Demo #{number}"
    user.public_profile_consented_at ||= Time.current if number <= 3
    user.tap { user.save! if user.changed? }
  end

  def self.demo_names = ['Ana Souza', 'Bruno Lima', 'Carla Mendes', 'Diego Rocha', 'Elisa Prado']

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
        users.each.with_index(1) { |user, number| demo_predict(pool, user, match, demo_guess(number, round, index)) }
      end
    end
  end

  def self.demo_predict(pool, user, match, guess)
    prediction = Bolao::Prediction.kept.find_or_initialize_by(pool:, user:, match:)
    return if prediction.persisted?

    prediction.home_guess, prediction.away_guess = guess
    prediction.save!(context: :backfill)
  end

  def self.demo_results(championship)
    [1, 2, 3, 4, 6].each do |round|
      demo_round(championship, round).each_with_index { |match, index| demo_close(match, demo_score(round, index)) }
    end
    demo_round(championship, 5).each { |match| match.start_match! if match.may_start_match? }
  end

  # Scouts go in before the scoring job, so prices move as after a real match.
  def self.demo_close(match, score)
    demo_finish(match, *score)
    demo_scouts(match)
    ProcessMatchPointsJob.perform_now(match.id, demo_scoring_token(match))
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
