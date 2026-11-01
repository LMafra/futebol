module Bolao
  # pool_id NULL = global rule.
  class ScoringRule < ApplicationRecord
    KINDS = %w[exact_score winner_and_goal_diff winner draw].freeze

    belongs_to :pool, class_name: 'Bolao::Pool', optional: true

    validates :kind, inclusion: { in: KINDS }, uniqueness: { scope: :pool_id }
    validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def self.ransackable_attributes(_auth_object = nil) = %w[kind pool_id]
    def self.ransackable_associations(_auth_object = nil) = %w[pool]

    def self.for(pool) = by_pool([pool&.id]).fetch(pool&.id)

    # Rules of many pools in one query: { pool_id => { kind: points } }, each pool's rules overriding the global ones.
    def self.by_pool(pool_ids)
      rules = where(pool_id: [nil, *pool_ids].uniq).group_by(&:pool_id)
      global = points_by_kind(rules[nil])

      pool_ids.uniq.index_with { |pool_id| global.merge(points_by_kind(rules[pool_id])) }
    end

    def self.points_by_kind(rules) = Array(rules).to_h { |rule| [rule.kind.to_sym, rule.points] }
    private_class_method :points_by_kind

    def to_s = "#{kind} (#{pool || 'global'})"
  end
end
