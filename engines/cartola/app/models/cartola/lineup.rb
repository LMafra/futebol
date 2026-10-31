module Cartola
  class Lineup < ApplicationRecord
    belongs_to :squad, class_name: 'Cartola::Squad'
    has_many :lineup_players, class_name: 'Cartola::LineupPlayer', dependent: :destroy
    has_many :players, through: :lineup_players, class_name: 'Core::Player'

    validates :round, numericality: { only_integer: true, in: 1..38 }, uniqueness: { scope: :squad_id }
  end
end
