module Core
  # Belongs to a manager (nil = the admin) and plays in the championships it is enrolled in (Inscrição).
  class Team < ApplicationRecord
    include Core::ImageAttachment

    # DDD + mobile (9 and eight digits) or landline (eight digits starting with 2-5), digits only.
    CAPTAIN_PHONE_FORMAT = /\A[1-9]{2}(?:9\d{8}|[2-5]\d{7})\z/

    image_attachment :crest
    belongs_to :manager, class_name: 'Core::User', optional: true, inverse_of: :managed_teams
    has_many :players, class_name: 'Core::Player', dependent: :restrict_with_error
    has_many :championship_teams, class_name: 'Core::ChampionshipTeam', inverse_of: :team, dependent: :destroy
    has_many :championships, through: :championship_teams
    has_many :home_matches, class_name: 'Core::Match', foreign_key: :home_team_id, inverse_of: :home_team,
                            dependent: :restrict_with_error
    has_many :away_matches, class_name: 'Core::Match', foreign_key: :away_team_id, inverse_of: :away_team,
                            dependent: :restrict_with_error

    normalizes :short_name, with: ->(short_name) { short_name.strip.upcase }
    normalizes :captain_name, with: ->(name) { name.squish.presence }
    # "+55 (11) 98765-4321" → "11987654321". The country code goes only past 11 digits: 55 is also a DDD.
    normalizes :captain_phone, with: lambda { |phone|
      digits = phone.gsub(/\D/, '')
      (digits.length > 11 ? digits.delete_prefix('55') : digits).presence
    }

    validates :name, presence: true
    validates :short_name, presence: true, length: { is: 3 },
                           uniqueness: { scope: :manager_id, message: 'já é usada por outro time seu' }
    validates :external_id, presence: true, uniqueness: true
    validates :captain_name, length: { maximum: 80 }
    validates :captain_phone, format: { with: CAPTAIN_PHONE_FORMAT, message: 'deve ter DDD e número' }, allow_nil: true
    validate :keep_manager_while_enrolled, on: :update

    scope :owned_by, ->(user) { where(manager_id: user&.id) }

    def self.ransackable_attributes(_auth_object = nil) = %w[name short_name external_id manager_id]
    def self.ransackable_associations(_auth_object = nil) = %w[manager]

    def to_s = name

    private

    def keep_manager_while_enrolled
      return unless will_save_change_to_manager_id? && championship_teams.exists?

      errors.add(:manager, 'só muda depois de remover as inscrições do time')
    end
  end
end
