# Small amateur championships (6-12 teams, single round robin, public and private) with their middle round
# today, so the home's "Jogos de hoje" mixes several championships. Dates use the app time zone, the same one
# the home filters by.
# The teams get no squads: the Esquadrão picker lists every player in the database, not only the championship's.
module Seeds
  def self.small_championships
    data = YAML.load_file(Rails.root.join('db/seeds/small_championships.yml'))
    data.each_with_index.map do |attributes, offset|
      championship = small_championship(attributes)
      teams = attributes.fetch('teams').map { |team| small_team(team) }
      today_round = teams.size / 2
      small_fixtures(championship, teams, today_round, offset)
      small_today(championship, today_round)
      small_results(championship, today_round)
      championship
    end
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

  # Past rounds and kickoffs over two hours ago end finished, kickoffs within two hours are live.
  def self.small_results(championship, today_round)
    championship.matches.where(round: ..today_round).order(:round, :external_id).each_with_index do |match, index|
      score = demo_score(match.round, index)
      if small_over?(match, today_round)
        demo_finish(match, *score)
      elsif match.match_date.past?
        small_start(match, score.map { |goals| goals / 2 })
      end
    end
  end

  def self.small_over?(match, today_round) = match.round < today_round || match.match_date <= 2.hours.ago

  def self.small_start(match, score)
    return unless match.may_start_match?

    match.home_score, match.away_score = score
    match.start_match!
  end
end
