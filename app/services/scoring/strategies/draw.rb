module Scoring
  module Strategies
    module Draw
      def self.kind = :draw

      def self.applies?(guess, result) = guess.inject(:==) && result.inject(:==)
    end
  end
end
