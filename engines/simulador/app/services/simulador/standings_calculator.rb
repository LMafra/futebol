module Simulador
  # Pure "what if" standings (ADR 0003 §4): no ActiveRecord, no I/O.
  #
  #   matches:   objects with id, home_team_id, away_team_id, home_score, away_score (e.g. Core::Match or Data)
  #   teams:     { team_id => name }; teams without matches still get a row
  #   overrides: { match_id => { home:, away: } }; replaces the score of that match
  #
  # Matches still without a score are left out (never counted as a draw). Ordered by points, wins, goal
  # difference, goals for and team name.
  class StandingsCalculator
    Fixture = Data.define(:id, :home_team_id, :away_team_id, :home_score, :away_score)

    Standing = Data.define(:position, :team_id, :team_name, :played, :wins, :draws, :losses, :goals_for,
                           :goals_against) do
      def points = (wins * 3) + draws
      def goal_difference = goals_for - goals_against
    end

    def self.call(matches:, teams:, overrides: {}) = new(matches:, teams:, overrides:).call

    def initialize(matches:, teams:, overrides: {})
      @matches = matches
      @teams = teams
      @overrides = overrides
    end

    def call
      tally = @teams.keys.index_with { { played: 0, wins: 0, draws: 0, losses: 0, goals_for: 0, goals_against: 0 } }
      @matches.each { |match| record(tally, match) }

      rank(tally.map { |team_id, stats| Standing.new(position: nil, team_id:, team_name: @teams[team_id], **stats) })
    end

    private

    def rank(standings)
      standings.sort_by { |row| [-row.points, -row.wins, -row.goal_difference, -row.goals_for, row.team_name] }
               .each.with_index(1).map { |row, position| row.with(position:) }
    end

    def record(tally, match)
      home, away = score_of(match)
      return if home.nil? || away.nil?

      add(tally.fetch(match.home_team_id), scored: home, conceded: away)
      add(tally.fetch(match.away_team_id), scored: away, conceded: home)
    end

    def score_of(match)
      override = @overrides[match.id]
      override ? override.values_at(:home, :away) : [match.home_score, match.away_score]
    end

    def add(stats, scored:, conceded:)
      stats[:played] += 1
      stats[:goals_for] += scored
      stats[:goals_against] += conceded
      stats[result_key(scored <=> conceded)] += 1
    end

    def result_key(comparison) = { 1 => :wins, 0 => :draws, -1 => :losses }.fetch(comparison)
  end
end
