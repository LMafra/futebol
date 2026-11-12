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

    # Teams that have a home or away match in any of the given championships.
    scope :playing_in, lambda { |championships|
      where(id: Core::Match.where(championship_id: championships).select(:home_team_id))
        .or(where(id: Core::Match.where(championship_id: championships).select(:away_team_id)))
    }
    scope :without_matches, lambda {
      where.not(id: Core::Match.select(:home_team_id)).where.not(id: Core::Match.select(:away_team_id))
    }

    def championships
      Core::Championship.where(id: home_matches.select(:championship_id))
                        .or(Core::Championship.where(id: away_matches.select(:championship_id)))
    end

    def to_s = name
  end
end
