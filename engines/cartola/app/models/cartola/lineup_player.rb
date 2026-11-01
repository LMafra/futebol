module Cartola
  class LineupPlayer < ApplicationRecord
    belongs_to :lineup, class_name: 'Cartola::Lineup'
    belongs_to :player, class_name: 'Core::Player'

    validates :player_id, uniqueness: { scope: :lineup_id }
  end
end
