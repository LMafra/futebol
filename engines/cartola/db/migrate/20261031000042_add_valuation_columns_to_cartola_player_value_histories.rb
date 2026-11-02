# Cartola::Valuation inputs kept with each re-pricing: the expected score and the player's game count in the
# championship. average_score now holds the player's championship average (no rows in production).
class AddValuationColumnsToCartolaPlayerValueHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :cartola_player_value_histories, :expected_score, :decimal, precision: 6, scale: 2, null: false,
                                                                           default: 0
    add_column :cartola_player_value_histories, :games_played, :integer, null: false, default: 1
    add_check_constraint :cartola_player_value_histories, 'games_played >= 1',
                         name: 'cartola_player_value_histories_games_played_positive', validate: false
  end
end
