module Cartola
  # A player's official scouts in a match and the points they are worth (Cartola::Scorer). Only participants have
  # a kept row: "Jogou" or at least one scout.
  class PlayerScore < ApplicationRecord
    include Discard::Model

    # G, A, DP, DE, CA, CV, GC; same bounds as the database check constraints.
    SCOUT_LIMITS = { goals: 0..20, assists: 0..20, penalty_saves: 0..3, saves: 0..20, yellow_cards: 0..2,
                     red_cards: 0..1, own_goals: 0..20 }.freeze
    SCOUTS = SCOUT_LIMITS.keys.freeze

    belongs_to :player, class_name: 'Core::Player'
    belongs_to :match, class_name: 'Core::Match'
    belongs_to :team, class_name: 'Core::Team'

    validates :points, numericality: true
    SCOUT_LIMITS.each do |scout, range|
      validates scout, numericality: { only_integer: true, in: range }
    end

    # [home, away] from the kept scouts: a side's goals plus the other side's own goals; nil without scouts.
    def self.score_for(match)
      totals = kept.where(match:).group(:team_id).pluck(:team_id, Arel.sql('SUM(goals)'), Arel.sql('SUM(own_goals)'))
      final_score(match, totals.to_h { |team_id, goals, own_goals| [team_id, [goals, own_goals]] }) if totals.any?
    end

    # [home, away] from { team_id => [goals, own_goals] }.
    def self.final_score(match, by_team)
      home, away = by_team.values_at(match.home_team_id, match.away_team_id).map { |pair| pair || [0, 0] }
      [home.first + away.last, away.first + home.last]
    end

    def stats = attributes.slice(*SCOUTS.map(&:to_s), 'played', 'highlight', 'clean_sheet').symbolize_keys
  end
end
