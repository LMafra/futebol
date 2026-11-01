class CreateCoreChampionships < ActiveRecord::Migration[8.1]
  def change
    create_table :core_championships do |t|
      t.string :name, null: false
      t.integer :season, null: false
      t.string :external_id, null: false

      t.timestamps
    end
    add_index :core_championships, :external_id, unique: true
    add_check_constraint :core_championships, 'season BETWEEN 1900 AND 2100', name: 'core_championships_season_range'
  end
end
