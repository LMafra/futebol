module Pools
  # @label Pools index
  class IndexComponentPreview < ViewComponent::Preview
    def default
      render IndexComponent.new(pools: sample_pools)
    end

    def loading
      render IndexComponent.new(state: :loading)
    end

    def empty
      render IndexComponent.new(pools: [], state: :empty)
    end

    def error
      render IndexComponent.new(pools: sample_pools, error: 'Código de bolão inválido.', state: :error)
    end

    private

    def sample_pools
      championship = Core::Championship.new(name: 'Brasileirão Série A', season: 2026)
      [
        Bolao::Pool.new(id: 1, name: 'Bolão da firma', code: 'K7P2QD', championship:),
        Bolao::Pool.new(id: 2, name: 'Família', code: 'HX4M9R', championship:)
      ]
    end
  end
end
