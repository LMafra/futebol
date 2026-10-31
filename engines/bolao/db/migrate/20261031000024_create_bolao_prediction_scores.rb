class CreateBolaoPredictionScores < ActiveRecord::Migration[8.1]
  def change
    create_table :bolao_prediction_scores do |t|
      t.references :prediction, null: false, foreign_key: { to_table: :bolao_predictions }, index: false
      t.integer :points, null: false
      t.uuid :scoring_token, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :bolao_prediction_scores, %i[prediction_id scoring_token], unique: true
    add_index :bolao_prediction_scores, :scoring_token
    add_index :bolao_prediction_scores, :discarded_at
    add_check_constraint :bolao_prediction_scores, 'points >= 0', name: 'bolao_prediction_scores_points_non_negative'
  end
end
