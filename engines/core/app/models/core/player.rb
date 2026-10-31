module Core
  class Player < ApplicationRecord
    POSITIONS = %w[GOL LAT ZAG MEI ATA].freeze

    belongs_to :team, class_name: 'Core::Team'

    validates :name, presence: true
    validates :position, inclusion: { in: POSITIONS }
    validates :shirt_number, numericality: { only_integer: true, in: 1..99 }, allow_nil: true
    validates :shirt_number, uniqueness: { scope: :team_id }, allow_nil: true
    validates :external_id, presence: true, uniqueness: true

    def to_s = name
  end
end
