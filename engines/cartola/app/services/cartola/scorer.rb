module Cartola
  module Scorer
    # stats: { goals:, assists:, yellow_cards:, red_cards: } (missing keys count as 0);
    # rules responds to goal_points, assist_points, yellow_card_penalty and red_card_penalty (Cartola::ScoringRule).
    def self.points(stats:, rules:)
      (stats.fetch(:goals, 0) * rules.goal_points) +
        (stats.fetch(:assists, 0) * rules.assist_points) -
        (stats.fetch(:yellow_cards, 0) * rules.yellow_card_penalty) -
        (stats.fetch(:red_cards, 0) * rules.red_card_penalty)
    end
  end
end
