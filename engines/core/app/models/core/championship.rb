module Core
  class Championship < ApplicationRecord
    include Core::ImageAttachment

    CARTOLA_LIMITS = {
      goalkeeper: :cartola_goalkeeper_limit, defender: :cartola_defender_limit,
      midfielder: :cartola_midfielder_limit, forward: :cartola_forward_limit
    }.freeze
    # Prize per final position, set by the championship's manager: { "first_place" => "R$ 500 e troféu", ... }.
    PRIZE_PLACES = %i[first_place second_place third_place].freeze
    # Modalidade (ADR 0006): stored value => label, per field.
    MODALITY = {
      kind: { 'campo' => 'Campo', 'society' => 'Society', 'futsal' => 'Futsal', 'futevolei' => 'Futevôlei' },
      gender: { 'masculino' => 'Masculino', 'feminino' => 'Feminino', 'misto' => 'Misto' },
      category: { 'infantil' => 'Infantil', 'base' => 'Base', 'adulto' => 'Adulto', 'master' => 'Master' },
      level: { 'amador' => 'Amador', 'profissional' => 'Profissional' }
    }.freeze
    # Esquadrão limits the Tipo suggests while the championship is a draft; the manager may still change them.
    CARTOLA_DEFAULTS = {
      'campo' => { goalkeeper: 1, defender: 2, midfielder: 3, forward: 3 },
      'society' => { goalkeeper: 1, defender: 2, midfielder: 2, forward: 2 },
      'futsal' => { goalkeeper: 1, defender: 1, midfielder: 1, forward: 2 },
      'futevolei' => { goalkeeper: 0, defender: 1, midfielder: 0, forward: 1 }
    }.freeze

    store_accessor :prize_rules, *PRIZE_PLACES
    image_attachment :logo
    MODALITY.each { |field, labels| enum field, labels.keys.index_with(&:itself), prefix: true, validate: true }
    # Rascunho: built step by step by the creation wizard and hidden from the public until published.
    enum :status, { draft: 'draft', published: 'published' }, validate: true

    has_many :matches, class_name: 'Core::Match', dependent: :restrict_with_error
    has_many :championship_teams, class_name: 'Core::ChampionshipTeam', inverse_of: :championship,
                                  dependent: :destroy
    has_many :teams, through: :championship_teams
    belongs_to :manager, class_name: 'Core::User', optional: true, inverse_of: :managed_championships

    validates :name, presence: true
    validates :season, numericality: { only_integer: true, in: 1900..2100 }
    validates :external_id, presence: true, uniqueness: true
    validates(*CARTOLA_LIMITS.values, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
    validates :cartola_initial_budget, :cartola_base_player_value, numericality: { greater_than_or_equal_to: 0 }
    validates :prize_description, length: { maximum: 2000 }
    validates(*PRIZE_PLACES, length: { maximum: 120 })
    validate :cartola_line_limits_positive
    before_save :apply_cartola_defaults, if: -> { draft? && will_save_change_to_kind? }

    scope :publicly_visible, -> { published.where(private: false) }
    scope :private_only, -> { where(private: true) }
    scope :managed_by, ->(user) { where(manager_id: user.id) }
    # Run by another manager or by no manager (the admin).
    scope :not_managed_by, ->(user) { where.not(manager_id: user.id).or(where(manager_id: nil)) }

    def self.ransackable_attributes(_auth_object = nil) = %w[name season external_id private status kind]

    def self.latest = published.order(season: :desc, id: :desc).first

    # Maximum players per position in a Cartola lineup: { goalkeeper: 1, defender: 2, midfielder: 3, forward: 3 }.
    def cartola_limits = CARTOLA_LIMITS.transform_values { |column| public_send(column) }

    def to_s = "#{name} #{season}"

    # "Society · Feminino · Adulto · Amador".
    def modality_label = MODALITY.map { |field, labels| labels[public_send(field)] }.join(' · ')

    def cartola_defaults = CARTOLA_DEFAULTS.fetch(kind)

    def prize? = prize_description.present? || PRIZE_PLACES.any? { |place| public_send(place).present? }

    private

    def apply_cartola_defaults
      CARTOLA_LIMITS.each { |slot, column| public_send(:"#{column}=", cartola_defaults.fetch(slot)) }
    end

    def cartola_line_limits_positive
      line_limits = cartola_limits.except(:goalkeeper).values
      return unless line_limits.all?(Integer) && line_limits.sum.zero?

      errors.add(:base, 'Defina pelo menos um jogador de linha (defensor, meio-campista ou atacante) no Cartola')
    end
  end
end
