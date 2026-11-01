module Cartola
  class Lineup < ApplicationRecord
    FORMATIONS = %w[3-4-3 3-5-2 4-3-3 4-4-2 4-5-1 5-3-2 5-4-1].freeze
    DEFAULT_FORMATION = '4-3-3'.freeze
    PLAYERS = 11
    BUDGET = 100
    LINES = { 'GOL' => :goalkeeper, 'LAT' => :defense, 'ZAG' => :defense, 'MEI' => :midfield,
              'ATA' => :attack }.freeze

    belongs_to :squad, class_name: 'Cartola::Squad'
    has_many :lineup_players, class_name: 'Cartola::LineupPlayer', dependent: :destroy, autosave: true
    has_many :players, through: :lineup_players, class_name: 'Core::Player'

    validates :round, numericality: { only_integer: true, in: 1..38 }, uniqueness: { scope: :squad_id }
    validates :formation, inclusion: { in: FORMATIONS }
    validate :eleven_players, :lines_match_formation, :within_budget

    # "4-3-3" => { goalkeeper: 1, defense: 4, midfield: 3, attack: 3 }
    def self.required_lines(formation)
      defense, midfield, attack = formation.split('-').map(&:to_i)
      { goalkeeper: 1, defense:, midfield:, attack: }
    end

    # Marks the dropped players for destruction and builds the new ones; nothing is written until save.
    def assign_players(new_players)
      new_ids = new_players.map(&:id)
      dropped, kept = lineup_players.partition { |lineup_player| new_ids.exclude?(lineup_player.player_id) }
      dropped.each(&:mark_for_destruction)
      kept_ids = kept.map(&:player_id)
      new_players.each { |player| lineup_players.build(player:) unless kept_ids.include?(player.id) }
    end

    def selected_players = lineup_players.reject(&:marked_for_destruction?).map(&:player)

    def total_cost = selected_players.sum { |player| player.cost || 0 }

    def remaining_budget = BUDGET - total_cost

    def players_by_line = selected_players.group_by { |player| LINES.fetch(player.position) }

    private

    def eleven_players
      count = selected_players.size
      errors.add(:players, "precisa de #{PLAYERS} jogadores (tem #{count})") unless count == PLAYERS
    end

    def lines_match_formation
      return unless FORMATIONS.include?(formation) && selected_players.size == PLAYERS

      actual = players_by_line.transform_values(&:size)
      return if self.class.required_lines(formation).all? { |line, count| actual.fetch(line, 0) == count }

      errors.add(:players, "não batem com a formação #{formation}")
    end

    def within_budget
      return if total_cost <= BUDGET

      errors.add(:players, "custam C$ #{format('%.2f', total_cost)}, acima do orçamento de C$ #{BUDGET}")
    end
  end
end
