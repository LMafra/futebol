module Cartola
  class PlayerValueHistory < ApplicationRecord
    belongs_to :player, class_name: 'Core::Player'
    belongs_to :championship, class_name: 'Core::Championship'
    belongs_to :match, class_name: 'Core::Match'

    validates :scoring_token, presence: true, uniqueness: { scope: :player_id }
    validates :previous_value, :value, numericality: { greater_than: 0 }
    validates :score, :average_score, :expected_score, :changed_at, presence: true
    validates :games_played, numericality: { only_integer: true, greater_than: 0 }
  end
end
