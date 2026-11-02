module Cartola
  class ScoringRule < ApplicationRecord
    DEFAULT_NAME = 'padrao'.freeze
    # Admin order: G, A, SG, DP, DE, CA, CV, GC, Jogou, Destaque (labels in config/locales/pt-BR.yml).
    POINT_COLUMNS = %i[goal_points assist_points clean_sheet_points penalty_save_points save_points
                       yellow_card_penalty red_card_penalty own_goal_penalty played_points highlight_points].freeze

    validates :name, presence: true, uniqueness: true
    validates(*POINT_COLUMNS, numericality: { greater_than_or_equal_to: 0 })

    def self.default = find_by!(name: DEFAULT_NAME)

    def self.ransackable_attributes(_auth_object = nil) = %w[name]

    def to_s = name
  end
end
