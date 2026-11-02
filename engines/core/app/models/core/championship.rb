module Core
  class Championship < ApplicationRecord
    CARTOLA_LIMITS = {
      goalkeeper: :cartola_goalkeeper_limit, defender: :cartola_defender_limit,
      midfielder: :cartola_midfielder_limit, forward: :cartola_forward_limit
    }.freeze

    has_many :matches, class_name: 'Core::Match', dependent: :restrict_with_error

    validates :name, presence: true
    validates :season, numericality: { only_integer: true, in: 1900..2100 }
    validates :external_id, presence: true, uniqueness: true
    validates(*CARTOLA_LIMITS.values, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
    validates :cartola_initial_budget, :cartola_base_player_value, numericality: { greater_than_or_equal_to: 0 }
    validate :cartola_line_limits_positive

    scope :publicly_visible, -> { where(private: false) }
    scope :private_only, -> { where(private: true) }

    def self.ransackable_attributes(_auth_object = nil) = %w[name season external_id private]

    def self.latest = order(season: :desc, id: :desc).first

    # Maximum players per position in a Cartola lineup: { goalkeeper: 1, defender: 2, midfielder: 3, forward: 3 }.
    def cartola_limits = CARTOLA_LIMITS.transform_values { |column| public_send(column) }

    # Teams with at least one match in the championship, home or away.
    def teams
      Core::Team.where(id: matches.select(:home_team_id)).or(Core::Team.where(id: matches.select(:away_team_id)))
    end

    def to_s = "#{name} #{season}"

    private

    def cartola_line_limits_positive
      line_limits = cartola_limits.except(:goalkeeper).values
      return unless line_limits.all?(Integer) && line_limits.sum.zero?

      errors.add(:base, 'Defina pelo menos um jogador de linha (defensor, meio-campista ou atacante) no Cartola')
    end
  end
end
