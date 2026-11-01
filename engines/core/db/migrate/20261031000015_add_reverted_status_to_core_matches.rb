class AddRevertedStatusToCoreMatches < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :core_matches, "status IN ('scheduled','live','finished','scored')",
                            name: 'matches_status_valid'
    add_check_constraint :core_matches, "status IN ('scheduled','live','finished','scored','reverted')",
                         name: 'matches_status_valid'

    remove_check_constraint :core_matches, "(status = 'scored') = (scores_calculated_at IS NOT NULL)",
                            name: 'matches_scored_has_timestamp'
    add_check_constraint :core_matches, "status <> 'scored' OR scores_calculated_at IS NOT NULL",
                         name: 'matches_scored_has_timestamp'
    add_check_constraint :core_matches, "scores_calculated_at IS NULL OR status IN ('finished','scored')",
                         name: 'matches_timestamp_after_finish'
  end
end
