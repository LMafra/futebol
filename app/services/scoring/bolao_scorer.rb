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
      kind = outcome(guess:, result:)
      kind ? rules.fetch(kind) : 0
    end

    # The first matching outcome kind (:exact_score, :winner_and_goal_diff, :winner, :draw), or nil for a miss.
    def self.outcome(guess:, result:) = OUTCOMES.find { |strategy| strategy.applies?(guess, result) }&.kind
  end
end
