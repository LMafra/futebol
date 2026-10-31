class CreateCorePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :core_players do |t|
      t.references :team, null: false, foreign_key: { to_table: :core_teams }
      t.string :name, null: false
      t.string :position, null: false
      t.integer :shirt_number
      t.string :external_id, null: false

      t.timestamps
    end
    add_index :core_players, :external_id, unique: true
    add_index :core_players, %i[team_id shirt_number], unique: true, where: 'shirt_number IS NOT NULL'
    add_check_constraint :core_players, "position IN ('GOL','LAT','ZAG','MEI','ATA')", name: 'players_position_valid'
    add_check_constraint :core_players, 'shirt_number BETWEEN 1 AND 99', name: 'players_shirt_number_range'
  end
end
