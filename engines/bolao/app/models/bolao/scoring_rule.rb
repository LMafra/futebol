module Bolao
  # Two bands: exact score, or right winner/draw with the wrong score. Scope: pool_id and championship_id both
  # NULL = global; championship_id = that championship; pool_id = override for one pool. Most specific wins.
  class ScoringRule < ApplicationRecord
    belongs_to :pool, class_name: 'Bolao::Pool', optional: true
    belongs_to :championship, class_name: 'Core::Championship', optional: true

    validates :exact_score_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :winner_points, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                              less_than_or_equal_to: :exact_score_points },
                              if: -> { exact_score_points.is_a?(Integer) }
    validates :pool_id, uniqueness: { scope: :championship_id }
    validate :single_scope

    def self.ransackable_attributes(_auth_object = nil) = %w[pool_id championship_id]
    def self.ransackable_associations(_auth_object = nil) = %w[pool championship]

    def self.global = find_by(pool_id: nil, championship_id: nil) || new

    def self.for(pool) = pool ? by_pool([pool]).fetch(pool.id) : global

    # Rules of many pools in one query: { pool_id => ScoringRule } (pool override, else championship, else global).
    def self.by_pool(pools)
      pools = pools.uniq
      rules = where(pool_id: [nil, *pools.map(&:id)], championship_id: [nil, *pools.map(&:championship_id)])
              .index_by { |rule| [rule.championship_id, rule.pool_id] }
      global = rules[[nil, nil]] || new

      pools.to_h { |pool| [pool.id, rules[[nil, pool.id]] || rules[[pool.championship_id, nil]] || global] }
    end

    # :exact, :winner (right winner, or a draw for a drawn match, with another score) or :miss.
    def self.result_for(prediction_home, prediction_away, actual_home, actual_away)
      if [prediction_home, prediction_away] == [actual_home, actual_away] then :exact
      elsif (prediction_home <=> prediction_away) == (actual_home <=> actual_away) then :winner
      else :miss
      end
    end

    def points_for(prediction_home, prediction_away, actual_home, actual_away)
      result = self.class.result_for(prediction_home, prediction_away, actual_home, actual_away)

      { points: { exact: exact_score_points, winner: winner_points, miss: 0 }.fetch(result), result: }
    end

    def scope_label = pool&.to_s || championship&.to_s || 'global'

    def to_s = "#{exact_score_points}/#{winner_points} (#{scope_label})"

    private

    def single_scope
      errors.add(:pool, 'não pode ser combinado com um campeonato') if pool_id && championship_id
    end
  end
end
