class CreateCoreChampionshipTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :core_championship_teams do |t|
      t.references :championship, null: false, index: false, foreign_key: { to_table: :core_championships }
      t.references :team, null: false, foreign_key: { to_table: :core_teams }
      t.timestamps
    end
    add_index :core_championship_teams, %i[championship_id team_id], unique: true
  end
end
