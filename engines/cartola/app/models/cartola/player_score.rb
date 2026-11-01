module Cartola
  class PlayerScore < ApplicationRecord
    include Discard::Model

    belongs_to :player, class_name: 'Core::Player'
    belongs_to :match, class_name: 'Core::Match'

    validates :points, numericality: true
  end
end
