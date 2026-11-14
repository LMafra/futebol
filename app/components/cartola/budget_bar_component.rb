module Cartola
  # budget: what the lineup can cost, i.e. the wallet balance plus the value of the players already bought.
  class BudgetBarComponent < Ui::BaseComponent
    attr_reader :spent, :budget

    def initialize(spent: nil, budget: nil, state: :default)
      super(state:)
      @spent = spent
      @budget = budget
      require_in_default_state!(:spent, spent)
      require_in_default_state!(:budget, budget)
    end

    private

    def over_budget? = spent > budget

    def remaining = budget - spent

    def percent = budget.zero? ? 100 : [(spent * 100 / budget).round, 100].min

    def money(value) = format('C$ %.2f', value)

    def value_text
      over_budget? ? "Estourou #{money(-remaining)} de #{money(budget)}" : "Gasto #{money(spent)} de #{money(budget)}"
    end
  end
end
