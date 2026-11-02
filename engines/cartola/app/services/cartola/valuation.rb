module Cartola
  # Player price after a game, by regression to the mean (ADR 0005):
  #   historical = (current − initial) × HISTORY_RATE, weighted 0 on the player's 1st game in the championship,
  #                0.5 on the 2nd and 3rd and 1 from the 4th on;
  #   expected   = current × EXPECTED_RATE + historical × weight;
  #   new price  = max(current + clamp((score − expected) / DAMPING, ±MAX_VARIATION), MIN_PRICE), to the cent.
  module Valuation
    EXPECTED_RATE = BigDecimal('0.45')
    HISTORY_RATE = BigDecimal('0.25')
    DAMPING = 4
    MAX_VARIATION = 5
    MIN_PRICE = BigDecimal('0.50')

    # games_played counts the game being priced: 1 is the player's first game in the championship.
    def self.history_weight(games_played)
      case games_played
      when ..1 then 0
      when 2..3 then BigDecimal('0.5')
      else 1
      end
    end

    def self.expected_score(current:, initial:, games_played:)
      (current.to_d * EXPECTED_RATE) + ((current.to_d - initial.to_d) * HISTORY_RATE * history_weight(games_played))
    end

    def self.new_price(current:, initial:, score:, games_played:)
      expected = expected_score(current:, initial:, games_played:)
      variation = ((score.to_d - expected) / DAMPING).clamp(-MAX_VARIATION, MAX_VARIATION)
      [current.to_d + variation, MIN_PRICE].max.round(2)
    end
  end
end
