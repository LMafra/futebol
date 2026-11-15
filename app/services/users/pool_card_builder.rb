module Users
  # Builds index cards (members count + position) for the signed-in user's pools without N+1.
  class PoolCardBuilder
    def initialize(user, pools)
      @user = user
      @pools = Array(pools)
    end

    def cards
      pools.map { |pool| card_for(pool) }
    end

    private

    attr_reader :user, :pools

    def card_for(pool)
      Pools::IndexComponent::PoolCard.new(
        pool:,
        position: positions.dig(pool.id, user.id),
        members_count: members_counts.fetch(pool.id, pool.memberships.size),
        show_code: reveal_code?(pool)
      )
    end

    def members_counts
      @members_counts ||= pools.to_h { |pool| [pool.id, pool.memberships.size] }
    end

    def positions
      @positions ||= pools.to_h { |pool| [pool.id, rank_pool(pool)] }
    end

    def rank_pool(pool)
      ordered = ordered_member_ids(pool)
      ordered.to_h { |user_id| [user_id, tied_position(ordered, pool, user_id)] }
    end

    def ordered_member_ids(pool)
      pool.memberships.map(&:user_id).sort_by { |user_id| [-points_for(pool.id, user_id), user_id] }
    end

    def tied_position(ordered, pool, user_id)
      points = points_for(pool.id, user_id)
      ordered.index { |other| points_for(pool.id, other) == points } + 1
    end

    def points_for(pool_id, user_id)
      points_by_pool_user.fetch([pool_id, user_id], 0)
    end

    def points_by_pool_user
      @points_by_pool_user ||= load_points
    end

    def load_points
      return {} if pools.empty?

      Bolao::PredictionScore.kept.joins(:prediction).merge(Bolao::Prediction.kept)
                            .where(bolao_predictions: { pool_id: pools.map(&:id) })
                            .group('bolao_predictions.pool_id', 'bolao_predictions.user_id')
                            .sum(:points)
    end

    def reveal_code?(pool)
      user.admin? || user.manager? || pool.owned_by?(user)
    end
  end
end
