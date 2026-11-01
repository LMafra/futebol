module Scoring
  # Pure: no I/O besides the rules handed in (or the Bolão rules lookup when none are given).
  class Engine
    SCORERS = { bolao: BolaoScorer, cartola: Cartola::Scorer }.freeze

    def self.scorer_for(game) = SCORERS.fetch(game&.to_sym, NullScorer)

    def self.score(game, **) = scorer_for(game).points(**)

    def self.points_for(prediction:, home:, away:, rules: Bolao::ScoringRule.for(prediction.pool))
      score(:bolao, guess: [prediction.home_guess, prediction.away_guess], result: [home, away], rules:)
    end
  end
end
