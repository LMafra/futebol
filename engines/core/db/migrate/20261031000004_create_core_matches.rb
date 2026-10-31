class CreateCoreMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :core_matches do |t|
      t.references :home_team, null: false, foreign_key: { to_table: :core_teams }
      t.references :away_team, null: false, foreign_key: { to_table: :core_teams }
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }
      t.datetime :match_date, null: false
      t.integer :home_score
      t.integer :away_score
      t.string :status, null: false, default: 'scheduled'
      t.datetime :scores_calculated_at
      t.uuid :scoring_token
      t.uuid :reversal_token
      t.string :external_id, null: false

      t.timestamps
    end
    add_index :core_matches, :external_id, unique: true
    add_index :core_matches, :scoring_token, unique: true, where: 'scoring_token IS NOT NULL'
    add_index :core_matches, :match_date

    add_check_constraint :core_matches, "status IN ('scheduled','live','finished','scored')",
                         name: 'matches_status_valid'
    add_check_constraint :core_matches, "(status = 'scored') = (scores_calculated_at IS NOT NULL)",
                         name: 'matches_scored_has_timestamp'
    add_check_constraint :core_matches, 'home_team_id <> away_team_id', name: 'matches_distinct_teams'
    add_check_constraint :core_matches, 'home_score >= 0 AND away_score >= 0', name: 'matches_scores_non_negative'
  end
end
