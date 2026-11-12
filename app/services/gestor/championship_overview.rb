module Gestor
  # Counters of the /gestor dashboard, one row per championship, in four grouped queries however many
  # championships the manager runs. Teams are the ones with a match in the championship, as in Core::TeamPolicy.
  class ChampionshipOverview
    Row = Data.define(:championship, :teams, :players, :matches, :scheduled, :pools)

    def self.call(championships) = new(championships).rows

    def initialize(championships)
      @championships = championships.to_a
      @ids = @championships.map(&:id)
    end

    def rows
      @championships.map do |championship|
        id = championship.id
        teams = team_ids.fetch(id, Set.new)
        Row.new(championship:, teams: teams.size, players: players_in(teams), matches: match_count(id),
                scheduled: matches_by_status.fetch([id, 'scheduled'], 0), pools: pools.fetch(id, 0))
      end
    end

    private

    def players_in(teams) = teams.sum { |team_id| players_by_team.fetch(team_id, 0) }

    def match_count(id) = matches_by_status.sum { |(championship_id, _), count| championship_id == id ? count : 0 }

    def matches = ::Core::Match.where(championship_id: @ids)

    def matches_by_status = @matches_by_status ||= matches.group(:championship_id, :status).count

    def team_ids
      @team_ids ||= matches.distinct.pluck(:championship_id, :home_team_id, :away_team_id)
                           .each_with_object({}) do |(id, home, away), teams|
        (teams[id] ||= Set.new).merge([home, away])
      end
    end

    def players_by_team
      @players_by_team ||= ::Core::Player.where(team_id: team_ids.values.reduce(Set.new, :|).to_a).group(:team_id).count
    end

    def pools = @pools ||= ::Bolao::Pool.where(championship_id: @ids).group(:championship_id).count
  end
end
