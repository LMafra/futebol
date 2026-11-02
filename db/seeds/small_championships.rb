# Small amateur championships (6-12 teams, single round robin, public and private) with their middle round
# today, so the home's "Jogos de hoje" mixes several championships. Dates use the app time zone, the same one
# the home filters by.
# Each has the demo users' Bolão (predictions up to today's round) and Esquadrão (lineups in the last finished
# round), so its home card shows a Top 3 of each. Finished matches get scouts and are scored like the demo's.
module Seeds
  def self.small_championships
    users = demo_users
    data = YAML.load_file(Rails.root.join('db/seeds/small_championships.yml'))
    data.each_with_index.map do |attributes, offset|
      championship = small_championship(attributes)
      small_round(championship, attributes.fetch('teams').map { |team| small_team(team) }, users, offset)
      championship
    end
  end

  # Squads get offsets past the Série A's 20 teams, 12 per championship (the largest size).
  def self.small_round(championship, teams, users, offset)
    today_round = teams.size / 2
    players(teams, offset: 20 + (12 * offset))
    small_fixtures(championship, teams, today_round, offset)
    small_today(championship, today_round)
    small_predictions(small_pool(championship, users), championship, users, today_round)
    small_results(championship, today_round)
    users.each.with_index(1) { |user, number| demo_lineup(user, championship, round: today_round - 1, pick: number) }
  end

  # Visibility follows the YAML on every load, so databases seeded before the flag existed catch up.
  def self.small_championship(attributes)
    championship = Core::Championship.find_or_create_by!(external_id: attributes.fetch('external_id')) do |record|
      record.assign_attributes(name: attributes.fetch('name'), season: 2026)
    end
    championship.update!(private: attributes.fetch('private', false))
    championship
  end

  def self.small_team(attributes)
    short_name = attributes.fetch('short_name')
    Core::Team.find_or_create_by!(external_id: "team-#{short_name.downcase}") do |team|
      team.assign_attributes(name: attributes.fetch('name'), short_name:)
    end
  end

  def self.small_fixtures(championship, teams, today_round, offset)
    double_round_robin(teams).first(teams.size - 1).each.with_index(1) do |pairings, round|
      pairings.each_with_index do |(home, away), index|
        Core::Match.find_or_create_by!(external_id: small_match_external_id(championship, round, home, away)) do |match|
          match.assign_attributes(home_team: home, away_team: away, championship:, round:,
                                  match_date: small_match_date(round - today_round, index + offset))
        end
      end
    end
  end

  # Weekly rounds around today, kickoffs every two hours from 10:00 so a round never crosses midnight.
  def self.small_match_date(weeks_from_today, slot)
    Date.current.in_time_zone + weeks_from_today.weeks + (10 + (2 * (slot % 6))).hours
  end

  def self.small_match_external_id(championship, round, home, away)
    format('%<championship>s-r%<round>02d-%<home>s-%<away>s', championship: championship.external_id,
                                                              round:, home: home.short_name.downcase,
                                                              away: away.short_name.downcase)
  end

  # On a later day the whole calendar moves by whole days, so the middle round is today again.
  def self.small_today(championship, today_round)
    first_kickoff = championship.matches.where(round: today_round).minimum(:match_date)
    days = (Date.current - first_kickoff.to_date).to_i
    return if days.zero?

    championship.matches.update_all(["match_date = match_date + (? * interval '1 day'), updated_at = ?",
                                     days, Time.current])
  end

  def self.small_pool(championship, users)
    pool = Bolao::Pool.find_or_create_by!(championship:, name: "Bolão #{championship.name}") do |new_pool|
      new_pool.owner = users.first
    end
    users.each { |user| pool.memberships.find_or_create_by!(user:) }
    pool
  end

  # Same order and index as small_results, so each guess is built around the score the match ends with.
  def self.small_predictions(pool, championship, users, today_round)
    small_played(championship, today_round).each_with_index do |match, index|
      users.each.with_index(1) do |user, number|
        demo_predict(pool, user, match, demo_guess(number, match.round, index))
      end
    end
  end

  # Past rounds and kickoffs over two hours ago end scored, kickoffs within two hours are live.
  def self.small_results(championship, today_round)
    small_played(championship, today_round).each_with_index do |match, index|
      score = demo_score(match.round, index)
      if small_over?(match, today_round)
        demo_close(match, score)
      elsif match.match_date.past?
        small_start(match, score.map { |goals| goals / 2 })
      end
    end
  end

  def self.small_played(championship, today_round)
    championship.matches.where(round: ..today_round).order(:round, :external_id)
  end

  def self.small_over?(match, today_round) = match.round < today_round || match.match_date <= 2.hours.ago

  def self.small_start(match, score)
    return unless match.may_start_match?

    match.home_score, match.away_score = score
    match.start_match!
  end
end
