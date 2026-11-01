module Cartola
  # Current market value of a player in a championship; absent until the first Cartola::ValueUpdateJob.
  class PlayerValue < ApplicationRecord
    belongs_to :player, class_name: 'Core::Player'
    belongs_to :championship, class_name: 'Core::Championship'

    validates :value, numericality: { greater_than: 0 }
    validates :player_id, uniqueness: { scope: :championship_id }

    # { player_id => value } in one query: the current value, else Core::Player#base_value_in(championship).
    def self.prices_for(players, championship)
      current = where(championship:, player_id: players.map(&:id)).pluck(:player_id, :value).to_h
      players.to_h { |player| [player.id, current.fetch(player.id) { player.base_value_in(championship) }] }
    end

    # Reversal: puts back the values a Scoring changed, unless a later Scoring already moved them again.
    def self.revert!(scoring_token)
      transaction do
        connection.exec_update(sanitize_sql_array([<<~SQL.squish, scoring_token]))
          UPDATE cartola_player_values SET value = history.previous_value, changed_at = NOW(), updated_at = NOW()
          FROM cartola_player_value_histories history
          WHERE history.scoring_token = ? AND cartola_player_values.player_id = history.player_id
            AND cartola_player_values.championship_id = history.championship_id
            AND cartola_player_values.value = history.value
        SQL
        PlayerValueHistory.where(scoring_token:).delete_all
      end
    end
  end
end
