module Core
  class Team < ApplicationRecord
    has_many :players, class_name: 'Core::Player', dependent: :restrict_with_error
    has_many :home_matches, class_name: 'Core::Match', foreign_key: :home_team_id, inverse_of: :home_team,
                            dependent: :restrict_with_error
    has_many :away_matches, class_name: 'Core::Match', foreign_key: :away_team_id, inverse_of: :away_team,
                            dependent: :restrict_with_error

    normalizes :short_name, with: ->(short_name) { short_name.strip.upcase }

    validates :name, presence: true
    validates :short_name, presence: true, length: { is: 3 }, uniqueness: true
    validates :external_id, presence: true, uniqueness: true

    def self.ransackable_attributes(_auth_object = nil) = %w[name short_name external_id]

    def to_s = name
  end
end
