module Cartola
  # @label Cartola budget bar
  class BudgetBarComponentPreview < ViewComponent::Preview
    def default
      render BudgetBarComponent.new(spent: 87.5)
    end

    def loading
      render BudgetBarComponent.new(state: :loading)
    end

    def empty
      render BudgetBarComponent.new(state: :empty)
    end

    def error
      render BudgetBarComponent.new(state: :error)
    end
  end
end
