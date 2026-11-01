module Bolao
  # @label Meus palpites
  class MyBetsComponentPreview < ViewComponent::Preview
    def default
      render MyBetsComponent.new(results: sample_results)
    end

    def loading
      render MyBetsComponent.new(state: :loading)
    end

    def empty
      render MyBetsComponent.new(state: :empty)
    end

    def error
      render MyBetsComponent.new(state: :error)
    end

    private

    def sample_results
      finished = sample_match('Flamengo', 'Palmeiras', 2, 1)
      [
        result(finished, [2, 1], :exact, 10),
        result(sample_match('Santos', 'Bahia', 1, 0), [3, 1], :winner, 5),
        result(sample_match('Grêmio', 'Internacional', 0, 0), [1, 2], :miss, 0),
        result(sample_match('Vasco', 'Botafogo', nil, nil), [1, 1], :pending, nil)
      ]
    end

    def result(match, (home_guess, away_guess), kind, points)
      prediction = Bolao::Prediction.new(match:, home_guess:, away_guess:)
      Bolao::BetResults::Result.new(prediction:, result: kind, points:)
    end

    def sample_match(home, away, home_score, away_score)
      Core::Match.new(home_team: Core::Team.new(name: home), away_team: Core::Team.new(name: away), home_score:,
                      away_score:)
    end
  end
end
