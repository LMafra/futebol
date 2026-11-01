module Ui
  # @label Standings table
  class StandingsTableComponentPreview < ViewComponent::Preview
    ROWS = [
      { position: 1, team_name: 'Flamengo', short_name: 'FLA', played: 33, wins: 21, draws: 7, losses: 5,
        goal_difference: 36, points: 70, form: %w[V V E V D] },
      { position: 2, team_name: 'Palmeiras', short_name: 'PAL', played: 33, wins: 20, draws: 7, losses: 6,
        goal_difference: 25, points: 67, form: %w[V E V V V] },
      { position: 3, team_name: 'Corinthians', short_name: 'COR', played: 33, wins: 14, draws: 9, losses: 10,
        goal_difference: 4, points: 51, form: %w[D E V D V] },
      { position: 4, team_name: 'São Paulo', short_name: 'SAO', played: 33, wins: 12, draws: 10, losses: 11,
        goal_difference: -2, points: 46, form: %w[E D D V E] }
    ].freeze

    def default
      render StandingsTableComponent.new(rows: ROWS)
    end

    def loading
      render StandingsTableComponent.new(state: :loading)
    end

    def empty
      render StandingsTableComponent.new(state: :empty)
    end

    def error
      render StandingsTableComponent.new(state: :error, log_path: '#')
    end
  end
end
