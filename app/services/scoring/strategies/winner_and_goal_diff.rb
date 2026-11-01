module Scoring
  module Strategies
    module WinnerAndGoalDiff
      def self.kind = :winner_and_goal_diff

      def self.applies?(guess, result)
        Winner.applies?(guess, result) && guess.inject(:-) == result.inject(:-)
      end
    end
  end
end
