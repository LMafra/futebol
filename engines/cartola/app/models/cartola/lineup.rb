module Cartola
  # How many players of each position slot a lineup may hold comes from its championship
  # (Core::Championship#cartola_limits). The formation is a UI preset that lays out the pitch; it limits nothing.
  class Lineup < ApplicationRecord
    FORMATIONS = %w[3-4-3 3-5-2 4-3-3 4-4-2 4-5-1 5-3-2 5-4-1].freeze
    DEFAULT_FORMATION = '4-3-3'.freeze
    SLOT_LABELS = { goalkeeper: 'goleiros', defender: 'defensores', midfielder: 'meio-campistas',
                    forward: 'atacantes' }.freeze

    belongs_to :squad, class_name: 'Cartola::Squad'
    belongs_to :championship, class_name: 'Core::Championship'
    has_many :lineup_players, class_name: 'Cartola::LineupPlayer', dependent: :destroy, autosave: true
    has_many :players, through: :lineup_players, class_name: 'Core::Player'

    validates :round, numericality: { only_integer: true, in: 1..38 },
                      uniqueness: { scope: %i[squad_id championship_id] }
    validates :formation, inclusion: { in: FORMATIONS }
    validate :some_players, :within_championship_limits, :one_captain
    before_save :release_captaincy

    # "4-3-3" => { goalkeeper: 1, defender: 4, midfielder: 3, forward: 3 }
    def self.preset(formation)
      defender, midfielder, forward = formation.split('-').map(&:to_i)
      { goalkeeper: 1, defender:, midfielder:, forward: }
    end

    def self.formations_for(championship)
      limits = championship.cartola_limits
      FORMATIONS.select { |formation| preset(formation).all? { |slot, count| count <= limits.fetch(slot) } }
    end

    # Marks the dropped players for destruction and builds the new ones; nothing is written until save.
    def assign_players(new_players)
      new_ids = new_players.map(&:id)
      dropped, kept = lineup_players.partition { |lineup_player| new_ids.exclude?(lineup_player.player_id) }
      dropped.each(&:mark_for_destruction)
      kept_ids = kept.map(&:player_id)
      new_players.reject { |player| kept_ids.include?(player.id) }
                 .each { |player| lineup_players.build(player:, position: player.slot) }
    end

    # The captain's points count twice in the ranking (Cartola::RankingsService); nothing is written until save.
    def assign_captain(player_id)
      kept_lineup_players.each { |lineup_player| lineup_player.captain = lineup_player.player_id == player_id.to_i }
    end

    def captain = kept_lineup_players.find(&:captain)&.player

    def captain_id = captain&.id

    def selected_players = kept_lineup_players.map(&:player)

    def players_by_slot = selected_players.group_by { |player| player.slot.to_sym }

    # Pitch slots per position: the preset, capped by the championship limits.
    def slots
      limits = championship.cartola_limits
      self.class.preset(formation).to_h { |slot, count| [slot, [count, limits.fetch(slot)].min] }
    end

    private

    def kept_lineup_players = lineup_players.reject(&:marked_for_destruction?)

    def one_captain
      return if selected_players.empty? || kept_lineup_players.one?(&:captain)

      errors.add(:base, 'Escolha um capitão entre os escalados')
    end

    # One captain per lineup in the database: the old one steps down before the lineup players are saved.
    def release_captaincy
      return if new_record?

      lineup_players.where(captain: true).where.not(id: kept_lineup_players.find(&:captain)&.id)
                    .update_all(captain: false, updated_at: Time.current)
    end

    def some_players
      errors.add(:players, 'escolha pelo menos um jogador') if selected_players.empty?
    end

    def within_championship_limits
      return if championship.nil?

      counts = players_by_slot.transform_values(&:size)
      championship.cartola_limits.each do |slot, limit|
        count = counts.fetch(slot, 0)
        next if count <= limit

        errors.add(:players, "têm #{count} #{SLOT_LABELS.fetch(slot)}; o limite do campeonato é #{limit}")
      end
    end
  end
end
