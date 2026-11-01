module Cartola
  class Squad < ApplicationRecord
    belongs_to :user, class_name: 'Core::User'
    has_many :lineups, class_name: 'Cartola::Lineup', dependent: :destroy

    validates :name, presence: true

    def self.ransackable_attributes(_auth_object = nil) = %w[name]

    def to_s = name
  end
end
