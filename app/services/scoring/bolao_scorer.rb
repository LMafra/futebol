module Scoring
  module BolaoScorer
    OUTCOMES = [
      Strategies::ExactScore,
      Strategies::WinnerAndGoalDiff,
      Strategies::Winner,
      Strategies::Draw
    ].freeze

    # guess/result are [home, away]; rules map each outcome kind to its points (Bolao::ScoringRule.for).
    def self.points(guess:, result:, rules:)
      outcome = OUTCOMES.find { |strategy| strategy.applies?(guess, result) }
      return 0 unless outcome

      rules.fetch(outcome.kind)
    end
  end
end
