module Core
  # The real table of a championship, from its finished matches and active point deductions
  # (Simulador::StandingsCalculator ordering):
  #   table(championship): the full table (public page, Admin and Gestor), every team of the matches or deductions;
  #   top(championships): the leaders of each championship (home cards) and every team with a deduction, in batch:
  #                       one query for the matches, one for the deductions and one for the team names, whatever the
  #                       number of championships. A championship without finished matches gets no rows.
  module ChampionshipStandingsService
    FINAL_STATUSES = %w[finished scored].freeze
    COLUMNS = %i[championship_id status id home_team_id away_team_id home_score away_score].freeze

    Table = Data.define(:standings, :teams)
    Top = Data.define(:leaders, :deducted)
    Row = Data.define(:position, :name, :points, :deduction, :deduction_reasons) do
      def detail = ("−#{deduction}" if deduction.positive?)
    end

    def self.table(championship)
      matches = championship.matches.with_team_crests.to_a
      deductions = championship.point_deductions.active.to_a
      teams = teams_of(matches, deductions)
      standings = Simulador::StandingsCalculator.call(matches: matches.select { |match| final?(match.status) },
                                                      teams: teams.to_h { |team| [team.id, team.name] }, deductions:)
      Table.new(standings:, teams:)
    end

    def self.teams_of(matches, deductions)
      teams = matches.flat_map { |match| [match.home_team, match.away_team] }
      missing = deductions.map(&:team_id) - teams.map(&:id)
      (teams + Core::Team.includes(crest_attachment: :blob).where(id: missing)).uniq.sort_by(&:name)
    end

    # { championship_id => Top }
    def self.top(championships, limit: 4)
      ids = championships.map(&:id)
      matches = Core::Match.where(championship_id: ids).pluck(*COLUMNS).group_by(&:first)
      deductions = Core::PointDeduction.active.where(championship_id: ids).group_by(&:championship_id)
      names = team_names(matches.values.flatten(1))
      ids.index_with { |id| top_of(standings(matches.fetch(id, []), deductions.fetch(id, []), names), limit) }
    end

    def self.top_of(rows, limit) = Top.new(leaders: rows.first(limit), deducted: rows.select { _1.deduction.positive? })

    def self.standings(matches, deductions, names)
      finished = matches.select { |_, status| final?(status) }
      return [] if finished.empty?

      Simulador::StandingsCalculator.call(matches: finished.map { |match| fixture(match) }, deductions:,
                                          teams: names.slice(*team_ids(matches))).map { |standing| row(standing) }
    end

    def self.row(standing)
      Row.new(position: standing.position, name: standing.team_name, points: standing.points,
              deduction: standing.deduction, deduction_reasons: standing.deduction_reasons)
    end

    def self.final?(status) = status.in?(FINAL_STATUSES)

    def self.team_names(matches) = Core::Team.where(id: team_ids(matches)).pluck(:id, :name).to_h

    def self.team_ids(matches) = matches.flat_map { |match| match.values_at(3, 4) }.uniq

    def self.fixture(match) = Simulador::StandingsCalculator::Fixture.new(*match.drop(2))
  end
end
