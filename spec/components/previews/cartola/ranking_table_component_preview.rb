module Cartola
  # @label Cartola ranking table
  class RankingTableComponentPreview < ViewComponent::Preview
    def default
      render RankingTableComponent.new(rows: sample_rows)
    end

    def loading
      render RankingTableComponent.new(state: :loading)
    end

    def empty
      render RankingTableComponent.new(rows: [], state: :empty)
    end

    def error
      render RankingTableComponent.new(state: :error)
    end

    private

    def sample_rows
      [['Ana', 42.5, 1], ['Bruno', 42.5, 1], ['Carla', 30, 3]].map do |name, value, position|
        RankingsService::Row.new(position:, user: Core::User.new(name:), value:)
      end
    end
  end
end
