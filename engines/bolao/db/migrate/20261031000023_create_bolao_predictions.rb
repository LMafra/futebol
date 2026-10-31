class CreateBolaoPredictions < ActiveRecord::Migration[8.1]
  def change
    create_table :bolao_predictions do |t|
      t.references :pool, null: false, foreign_key: { to_table: :bolao_pools }
      t.references :user, null: false, foreign_key: { to_table: :core_users }
      t.references :match, null: false, foreign_key: { to_table: :core_matches }
      t.integer :home_guess, null: false
      t.integer :away_guess, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :bolao_predictions, :discarded_at
    add_index :bolao_predictions, %i[pool_id user_id match_id], unique: true, where: 'discarded_at IS NULL',
                                                                name: 'index_bolao_predictions_kept_unique'
    add_check_constraint :bolao_predictions, 'home_guess >= 0 AND away_guess >= 0',
                         name: 'bolao_predictions_guesses_non_negative'
  end
end
