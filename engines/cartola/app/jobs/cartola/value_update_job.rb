module Cartola
  # Re-prices the players scored in a match after its Scoring:
  #   new value = current value × (1 + (player score − match average) / 100), at most ±20% per round.
  # The current value starts as the player's base value. One history row per player and scoring_token makes
  # retries no-ops; PlayerValue.revert! undoes it on a Reversal.
  class ValueUpdateJob < ApplicationJob
    MAX_CHANGE = BigDecimal('0.2')
    MIN_VALUE = BigDecimal('0.01')

    queue_as :default

    def perform(match_id, scoring_token)
      return if PlayerValueHistory.exists?(scoring_token:)

      match = Core::Match.find(match_id)
      scores = PlayerScore.kept.where(match:).includes(:player).to_a
      return if scores.empty?

      reprice!(match, scoring_token, scores)
    end

    def self.new_value(current, score:, average:)
      raw = current * (1 + ((score - average).to_d / 100))
      raw.clamp(current * (1 - MAX_CHANGE), current * (1 + MAX_CHANGE)).round(2).clamp(MIN_VALUE, nil)
    end

    private

    def reprice!(match, scoring_token, scores)
      average = scores.sum(&:points) / scores.size
      prices = PlayerValue.prices_for(scores.map(&:player), match.championship)
      shared = shared_attributes(match, scoring_token, average)
      changes = scores.filter_map { |score| change_for(score, prices.fetch(score.player_id), average)&.merge(shared) }
      save!(changes) if changes.any?
    end

    def shared_attributes(match, scoring_token, average)
      { championship_id: match.championship_id, match_id: match.id, scoring_token:, average_score: average.round(2),
        changed_at: Time.current }
    end

    def change_for(score, current, average)
      return unless current.positive?

      { player_id: score.player_id, previous_value: current, score: score.points,
        value: self.class.new_value(current, score: score.points, average:) }
    end

    def save!(changes)
      PlayerValue.transaction do
        PlayerValue.upsert_all(changes.map { |change| change.slice(:player_id, :championship_id, :value, :changed_at) },
                               unique_by: %i[player_id championship_id], update_only: %i[value changed_at])
        PlayerValueHistory.insert_all(changes, unique_by: %i[player_id scoring_token])
      end
    end
  end
end
