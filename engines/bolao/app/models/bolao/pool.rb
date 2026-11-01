module Bolao
  class Pool < ApplicationRecord
    belongs_to :championship, class_name: 'Core::Championship'
    belongs_to :owner, class_name: 'Core::User'
    has_many :predictions, class_name: 'Bolao::Prediction', dependent: :restrict_with_error
    has_many :scoring_rules, class_name: 'Bolao::ScoringRule', dependent: :destroy

    validates :name, presence: true

    def self.ransackable_attributes(_auth_object = nil) = %w[name championship_id]
    def self.ransackable_associations(_auth_object = nil) = %w[championship]

    def to_s = name
  end
end
