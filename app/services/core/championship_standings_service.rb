module Core
  # Leaders of the real table of each championship (home cards), in batch: one query for the matches and one for
  # the team names, whatever the number of championships. Only finished matches count (Simulador::StandingsCalculator
  # ordering); a championship with none of them gets no rows.
  module ChampionshipStandingsService
    FINAL_STATUSES = %w[finished scored].freeze
    COLUMNS = %i[championship_id status id home_team_id away_team_id home_score away_score].freeze

    Row = Data.define(:position, :name, :points)

    # { championship_id => [Row] }
    def self.top(championships, limit: 4)
      matches = Core::Match.where(championship_id: championships.map(&:id)).pluck(*COLUMNS).group_by(&:first)
      names = Core::Team.where(id: team_ids(matches.values.flatten(1))).pluck(:id, :name).to_h
      championships.to_h { |championship| [championship.id, leaders(matches.fetch(championship.id, []), names, limit)] }
    end

    def self.leaders(matches, names, limit)
      finished = matches.select { |_, status| status.in?(FINAL_STATUSES) }
      return [] if finished.empty?

      standings = Simulador::StandingsCalculator.call(matches: finished.map { |match| fixture(match) },
                                                      teams: names.slice(*team_ids(matches)))
      standings.first(limit).map { |row| Row.new(position: row.position, name: row.team_name, points: row.points) }
    end

    def self.team_ids(matches) = matches.flat_map { |match| match.values_at(3, 4) }.uniq

    def self.fixture(match) = Simulador::StandingsCalculator::Fixture.new(*match.drop(2))
  end
end
