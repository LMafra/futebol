class CreateCoreTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :core_teams do |t|
      t.string :name, null: false
      t.string :short_name, null: false
      t.string :crest_url
      t.string :external_id, null: false

      t.timestamps
    end
    add_index :core_teams, :external_id, unique: true
    add_index :core_teams, :short_name, unique: true
    add_check_constraint :core_teams, 'char_length(short_name) = 3', name: 'core_teams_short_name_length'
  end
end
