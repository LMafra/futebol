module Cartola
  # Best athletes of the given championships by kept PlayerScore points, in one grouped query plus the preload of
  # players and teams. J counts the matches with "Jogou"; ties share the position.
  module TopPlayersService
    Row = Data.define(:position, :name, :detail, :games, :goals, :assists, :points)

    def self.call(championships, limit: 10)
      totals = PlayerScore.kept.joins(:match).where(core_matches: { championship_id: championships.map(&:id) })
                          .group(:player_id).order(Arel.sql('SUM(points) DESC'), :player_id).limit(limit)
                          .select(:player_id, 'COUNT(*) FILTER (WHERE played) AS games', 'SUM(goals) AS goals',
                                  'SUM(assists) AS assists', 'SUM(points) AS total_points')
                          .preload(player: :team)
      rows(totals)
    end

    def self.rows(totals)
      totals.each_with_index.with_object([]) do |(total, index), rows|
        position = rows.last&.points == total.total_points ? rows.last.position : index + 1
        rows << row_for(total, position)
      end
    end

    def self.row_for(total, position)
      Row.new(position:, name: total.player.name, detail: total.player.team&.short_name, games: total.games,
              goals: total.goals, assists: total.assists, points: total.total_points)
    end

    private_class_method :rows, :row_for
  end
end
