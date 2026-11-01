module Scoring
  module Strategies
    module ExactScore
      def self.kind = :exact_score

      def self.applies?(guess, result) = guess == result
    end
  end
end
