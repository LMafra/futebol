# base_value NULL = the championship's cartola_base_player_value. The old cost 0 meant "not priced" (production
# seeds), so only positive costs are carried over.
class ReplaceCostWithBaseValueOnCorePlayers < ActiveRecord::Migration[8.1]
  def up
    add_column :core_players, :base_value, :decimal, precision: 6, scale: 2
    add_check_constraint :core_players, 'base_value IS NULL OR base_value >= 0',
                         name: 'players_base_value_non_negative', validate: false

    safety_assured do
      execute 'UPDATE core_players SET base_value = cost WHERE cost > 0'
      validate_check_constraint :core_players, name: 'players_base_value_non_negative'
      remove_check_constraint :core_players, name: 'players_cost_non_negative'
      remove_column :core_players, :cost
    end
  end

  def down
    add_column :core_players, :cost, :decimal, precision: 5, scale: 2, null: false, default: 0

    safety_assured do
      execute 'UPDATE core_players SET cost = base_value WHERE base_value IS NOT NULL'
      add_check_constraint :core_players, 'cost >= 0', name: 'players_cost_non_negative'
      remove_check_constraint :core_players, name: 'players_base_value_non_negative'
      remove_column :core_players, :base_value
    end
  end
end
