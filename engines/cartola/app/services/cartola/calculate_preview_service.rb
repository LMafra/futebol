module Cartola
  # Dry-run: reads the lineup and rules, never writes (no PlayerScore rows).
  class CalculatePreviewService
    def self.call(lineup:, stats:, rules: ScoringRule.default)
      player_points = lineup.players.to_h do |player|
        [player.id, Scorer.points(stats: stats.fetch(player.id, {}), rules:)]
      end.freeze

      PreviewResult.new(player_points:, total: player_points.values.sum)
    end
  end
end
