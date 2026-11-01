module Cartola
  class LineupPlayer < ApplicationRecord
    belongs_to :lineup, class_name: 'Cartola::Lineup'
    belongs_to :player, class_name: 'Core::Player'

    before_validation { self.position ||= player&.slot }

    validates :player_id, uniqueness: { scope: :lineup_id }
    validates :position, inclusion: { in: Core::Player::SLOTS }
    validate :position_matches_player

    private

    def position_matches_player
      return if player.nil? || position == player.slot

      errors.add(:position, "não corresponde à posição do jogador (#{player.position})")
    end
  end
end
