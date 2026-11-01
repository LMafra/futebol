module Pools
  # @label New pool
  class NewComponentPreview < ViewComponent::Preview
    def default
      render NewComponent.new(pool: Bolao::Pool.new, championships: sample_championships)
    end

    def loading
      render NewComponent.new(state: :loading)
    end

    def empty
      render NewComponent.new(pool: Bolao::Pool.new, championships: [], state: :empty)
    end

    def error
      pool = Bolao::Pool.new.tap { |record| record.errors.add(:name, :blank) }
      render NewComponent.new(pool:, championships: sample_championships, state: :error)
    end

    private

    def sample_championships
      [Core::Championship.new(id: 1, name: 'Brasileirão Série A', season: 2026)]
    end
  end
end
