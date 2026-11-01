module Ui
  # @label Prediction form
  class PredictionFormComponentPreview < ViewComponent::Preview
    def default
      render PredictionFormComponent.new(match: sample_match, prediction: Bolao::Prediction.new(pool_id: 1))
    end

    def loading
      render PredictionFormComponent.new(state: :loading)
    end

    def empty
      prediction = Bolao::Prediction.new(pool_id: 1, home_guess: 2, away_guess: 1)
      render PredictionFormComponent.new(match: sample_match, prediction:, state: :empty)
    end

    def error
      prediction = Bolao::Prediction.new(pool_id: 1, home_guess: -1, away_guess: 0)
      prediction.errors.add(:base, 'Palpites encerrados para esta partida.')
      prediction.errors.add(:home_guess, 'deve ser maior ou igual a 0')
      render PredictionFormComponent.new(match: sample_match, prediction:, state: :error)
    end

    private

    def sample_match
      Core::Match.new(id: 1, match_date: 2.days.from_now, status: 'scheduled')
    end
  end
end
