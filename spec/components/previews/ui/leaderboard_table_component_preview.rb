module Ui
  # @label Leaderboard table
  class LeaderboardTableComponentPreview < ViewComponent::Preview
    Row = Core::ChampionshipRankingsService::Row
    Player = Data.define(:position, :name, :detail, :games, :goals, :points)

    ROWS = [Row.new(position: 1, user_name: 'Ana S.', points: 42),
            Row.new(position: 1, user_name: 'Bruno L.', points: 42),
            Row.new(position: 3, user_name: 'Participante', points: 37)].freeze
    PLAYERS = [Player.new(position: 1, name: 'Pedro', detail: 'FLA', games: 10, goals: 9, points: BigDecimal('88.5')),
               Player.new(position: 2, name: 'Hulk', detail: 'CAM', games: 11, goals: 7, points: BigDecimal('80.2'))]
              .freeze

    # @param compact toggle "Home card variant"
    # @param players toggle "Top athletes, with extra columns"
    def default(compact: false, players: false)
      unless players
        return render LeaderboardTableComponent.new(rows: ROWS, texts: { label: 'Ranking do Bolão' }, compact:)
      end

      render LeaderboardTableComponent.new(rows: PLAYERS, texts: { label: 'Top atletas', name_header: 'Atleta' },
                                           columns: { games: %w[J Jogos], goals: %w[G Gols] }, compact:)
    end

    def loading
      render LeaderboardTableComponent.new(state: :loading)
    end

    def empty
      render LeaderboardTableComponent.new(state: :empty)
    end

    def error
      render LeaderboardTableComponent.new(state: :error)
    end
  end
end
