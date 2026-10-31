module Bolao
  # pool_id NULL = global rule. FK to bolao_pools arrives with the pools table (TICKET-0004).
  class ScoringRule < ApplicationRecord
    KINDS = %w[exact_score winner_and_goal_diff winner draw].freeze

    validates :kind, inclusion: { in: KINDS }, uniqueness: { scope: :pool_id }
    validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Global rules first so pool overrides win when the hash is built.
    def self.for(pool)
      where(pool_id: [nil, pool&.id].uniq)
        .order(Arel.sql('pool_id NULLS FIRST'))
        .to_h { |rule| [rule.kind.to_sym, rule.points] }
    end
  end
end
