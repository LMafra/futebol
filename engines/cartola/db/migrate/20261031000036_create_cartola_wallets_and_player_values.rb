class CreateCartolaWalletsAndPlayerValues < ActiveRecord::Migration[8.1]
  def change
    create_table :cartola_wallets do |t|
      t.references :user, null: false, foreign_key: { to_table: :core_users }, index: false
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }
      t.decimal :balance, precision: 10, scale: 2, null: false
      t.timestamps
    end
    add_index :cartola_wallets, %i[user_id championship_id], unique: true
    add_check_constraint :cartola_wallets, 'balance >= 0', name: 'cartola_wallets_balance_non_negative'

    create_table :cartola_player_values do |t|
      t.references :player, null: false, foreign_key: { to_table: :core_players }, index: false
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }
      t.decimal :value, precision: 6, scale: 2, null: false
      t.datetime :changed_at, null: false
      t.timestamps
    end
    add_index :cartola_player_values, %i[player_id championship_id], unique: true
    add_check_constraint :cartola_player_values, 'value > 0', name: 'cartola_player_values_value_positive'

    create_table :cartola_player_value_histories do |t|
      t.references :player, null: false, foreign_key: { to_table: :core_players }, index: false
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }
      t.references :match, null: false, foreign_key: { to_table: :core_matches }
      t.uuid :scoring_token, null: false
      t.decimal :previous_value, precision: 6, scale: 2, null: false
      t.decimal :value, precision: 6, scale: 2, null: false
      t.decimal :score, precision: 6, scale: 2, null: false
      t.decimal :average_score, precision: 6, scale: 2, null: false
      t.datetime :changed_at, null: false
      t.timestamps
    end
    add_index :cartola_player_value_histories, %i[player_id scoring_token], unique: true
    add_index :cartola_player_value_histories, :scoring_token
    add_check_constraint :cartola_player_value_histories, 'previous_value > 0 AND value > 0',
                         name: 'cartola_player_value_histories_values_positive'
  end
end
