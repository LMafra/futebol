module Pools
  # @label Pool
  class ShowComponentPreview < ViewComponent::Preview
    def default
      render ShowComponent.new(pool: sample_pool, memberships: sample_memberships, can_destroy: true)
    end

    def loading
      render ShowComponent.new(state: :loading)
    end

    def empty
      render ShowComponent.new(pool: sample_pool, state: :empty)
    end

    def error
      render ShowComponent.new(state: :error)
    end

    private

    def sample_pool
      Bolao::Pool.new(id: 1, name: 'Bolão da firma', code: 'K7P2QD', owner: Core::User.new(id: 3, name: 'Carla Lima'),
                      championship: Core::Championship.new(name: 'Brasileirão Série A', season: 2026))
    end

    def sample_memberships
      [
        Bolao::PoolMembership.new(user: Core::User.new(id: 1, name: 'Ana Souza'), user_id: 1, joined_at: 3.weeks.ago),
        Bolao::PoolMembership.new(user: Core::User.new(id: 2, email_address: 'bruno@futebol.dev'), user_id: 2,
                                  joined_at: 2.days.ago)
      ]
    end
  end
end
