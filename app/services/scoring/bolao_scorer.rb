module Scoring
  module BolaoScorer
    # guess/result are [home, away]; rules is the Bolao::ScoringRule in force (Bolao::ScoringRule.for).
    def self.points(guess:, result:, rules:) = rules.points_for(*guess, *result).fetch(:points)
  end
end
