module Core
  class Player < ApplicationRecord
    POSITIONS = %w[GOL LAT ZAG MEI ATA].freeze
    # Stored positions stay in the Brazilian abbreviations; Cartola limits work on these four slots.
    POSITION_SLOTS = { 'GOL' => 'goalkeeper', 'LAT' => 'defender', 'ZAG' => 'defender', 'MEI' => 'midfielder',
                       'ATA' => 'forward' }.freeze
    SLOTS = %w[goalkeeper defender midfielder forward].freeze

    belongs_to :team, class_name: 'Core::Team'

    validates :name, presence: true
    validates :position, inclusion: { in: POSITIONS }
    validates :shirt_number, numericality: { only_integer: true, in: 1..99 }, allow_nil: true
    validates :shirt_number, uniqueness: { scope: :team_id }, allow_nil: true
    validates :external_id, presence: true, uniqueness: true
    validates :base_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    def self.ransackable_attributes(_auth_object = nil) = %w[name position team_id external_id]
    def self.ransackable_associations(_auth_object = nil) = %w[team]

    def slot = POSITION_SLOTS[position]

    # base_value, or the championship default when the player has none.
    def base_value_in(championship) = base_value || championship.cartola_base_player_value

    def to_s = name
  end
end
