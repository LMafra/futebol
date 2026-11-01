class AddCostToCorePlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :core_players, :cost, :decimal, precision: 5, scale: 2, null: false, default: 0
    add_check_constraint :core_players, 'cost >= 0', name: 'players_cost_non_negative'
  end
end
