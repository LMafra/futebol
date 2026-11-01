module Cartola
  class BudgetBarComponent < Ui::BaseComponent
    attr_reader :spent, :budget

    def initialize(spent: nil, budget: Cartola::Lineup::BUDGET, state: :default)
      super(state:)
      @spent = spent
      @budget = budget
      require_in_default_state!(:spent, spent)
    end

    private

    def over_budget? = spent > budget

    def remaining = budget - spent

    def percent = budget.zero? ? 100 : [(spent * 100 / budget).round, 100].min

    def money(value) = format('C$ %.2f', value)
  end
end
