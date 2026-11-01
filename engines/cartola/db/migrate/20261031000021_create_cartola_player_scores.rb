class CreateCartolaPlayerScores < ActiveRecord::Migration[8.1]
  def change
    create_table :cartola_player_scores do |t|
      t.references :player, null: false, foreign_key: { to_table: :core_players }
      t.references :match, null: false, foreign_key: { to_table: :core_matches }
      t.decimal :points, precision: 6, scale: 2, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :cartola_player_scores, :discarded_at
    add_index :cartola_player_scores, %i[player_id match_id], unique: true, where: 'discarded_at IS NULL',
                                                              name: 'index_cartola_player_scores_kept_unique'
  end
end
