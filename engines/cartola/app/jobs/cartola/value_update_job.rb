module Cartola
  # Re-prices the players who played a match after its Scoring, with Cartola::Valuation. The score is the
  # player's own points (the captain bonus belongs to the lineup, not to the player); the current value starts
  # as the player's base value, which is also the initial price. games_played and average_score count the games
  # already priced in the championship plus this one. One history row per player and scoring_token makes
  # retries no-ops; PlayerValue.revert! undoes it on a Reversal.
  class ValueUpdateJob < ApplicationJob
    queue_as :default

    def perform(match_id, scoring_token)
      return if PlayerValueHistory.exists?(scoring_token:)

      match = Core::Match.find(match_id)
      scores = PlayerScore.kept.where(match:, played: true).includes(:player).to_a
      reprice!(match, scoring_token, scores) if scores.any?
    end

    private

    def reprice!(match, scoring_token, scores)
      championship = match.championship
      prices = PlayerValue.prices_for(scores.map(&:player), championship)
      history = priced_games(championship, scores)
      changes = scores.filter_map do |score|
        change_for(score, prices.fetch(score.player_id), championship, history.fetch(score.player_id, [0, 0]))
          &.merge(shared_attributes(match, scoring_token))
      end
      save!(changes) if changes.any?
    end

    def shared_attributes(match, scoring_token)
      @shared_attributes ||= { championship_id: match.championship_id, match_id: match.id, scoring_token:,
                               changed_at: Time.current }
    end

    # { player_id => [games, points] } already priced in the championship.
    def priced_games(championship, scores)
      PlayerValueHistory.where(championship:, player_id: scores.map(&:player_id)).group(:player_id)
                        .pluck(:player_id, Arel.sql('COUNT(*)'), Arel.sql('SUM(score)'))
                        .to_h { |player_id, games, points| [player_id, [games, points]] }
    end

    def change_for(score, current, championship, (priced, priced_points))
      return unless current.positive?

      games_played = priced + 1
      pricing = { current:, initial: score.player.base_value_in(championship), games_played: }
      { player_id: score.player_id, previous_value: current, score: score.points, games_played:,
        average_score: ((priced_points + score.points) / games_played).round(2),
        expected_score: Valuation.expected_score(**pricing).round(2),
        value: Valuation.new_price(**pricing, score: score.points) }
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
