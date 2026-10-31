module Scoring
  module Strategies
    module Winner
      def self.kind = :winner

      def self.applies?(guess, result)
        side = guess.inject(:<=>)
        !side.zero? && side == result.inject(:<=>)
      end
    end
  end
end
