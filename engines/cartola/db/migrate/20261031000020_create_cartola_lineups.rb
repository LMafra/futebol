class CreateCartolaLineups < ActiveRecord::Migration[8.1]
  def change
    create_table :cartola_lineups do |t|
      t.references :squad, null: false, foreign_key: { to_table: :cartola_squads }
      t.integer :round, null: false

      t.timestamps
    end
    add_index :cartola_lineups, %i[squad_id round], unique: true
    add_check_constraint :cartola_lineups, 'round BETWEEN 1 AND 38', name: 'cartola_lineups_round_range'

    create_table :cartola_lineup_players do |t|
      t.references :lineup, null: false, foreign_key: { to_table: :cartola_lineups }
      t.references :player, null: false, foreign_key: { to_table: :core_players }

      t.timestamps
    end
    add_index :cartola_lineup_players, %i[lineup_id player_id], unique: true
  end
end
