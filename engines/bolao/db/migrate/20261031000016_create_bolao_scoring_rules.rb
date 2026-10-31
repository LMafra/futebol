class CreateBolaoScoringRules < ActiveRecord::Migration[8.1]
  def change
    create_table :bolao_scoring_rules do |t|
      t.bigint :pool_id
      t.string :kind, null: false
      t.integer :points, null: false

      t.timestamps
    end
    add_index :bolao_scoring_rules, %i[pool_id kind], unique: true, nulls_not_distinct: true

    add_check_constraint :bolao_scoring_rules, 'points >= 0', name: 'bolao_scoring_rules_points_non_negative'
    add_check_constraint :bolao_scoring_rules,
                         "kind IN ('exact_score','winner_and_goal_diff','winner','draw')",
                         name: 'bolao_scoring_rules_kind_valid'
  end
end
