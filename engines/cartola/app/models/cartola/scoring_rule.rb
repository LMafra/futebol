module Cartola
  class ScoringRule < ApplicationRecord
    DEFAULT_NAME = 'padrao'.freeze
    POINT_COLUMNS = %i[goal_points assist_points yellow_card_penalty red_card_penalty].freeze

    validates :name, presence: true, uniqueness: true
    validates(*POINT_COLUMNS, numericality: { greater_than_or_equal_to: 0 })

    def self.default = find_by!(name: DEFAULT_NAME)
  end
end
