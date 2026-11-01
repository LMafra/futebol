# One row per scope (global, championship or pool) with two bands instead of one row per outcome kind.
# Old bands: exact_score → exact_score_points; winner_and_goal_diff, winner and draw → winner_points,
# which takes the old `winner` value (the 7 and 3 bands disappear). Scopes missing a band inherit it from the
# global rows, then from the defaults (10/5).
class ConsolidateBolaoScoringRules < ActiveRecord::Migration[8.1]
  def up
    add_column :bolao_scoring_rules, :exact_score_points, :integer
    add_column :bolao_scoring_rules, :winner_points, :integer
    add_column :bolao_scoring_rules, :championship_id, :bigint

    safety_assured do
      consolidate_rows
      say "bolao_scoring_rules consolidated into #{select_value('SELECT count(*) FROM bolao_scoring_rules')} row(s)"

      change_column_default :bolao_scoring_rules, :exact_score_points, 10
      change_column_default :bolao_scoring_rules, :winner_points, 5
      change_column_null :bolao_scoring_rules, :exact_score_points, false
      change_column_null :bolao_scoring_rules, :winner_points, false

      remove_index :bolao_scoring_rules, %i[pool_id kind]
      remove_check_constraint :bolao_scoring_rules, name: 'bolao_scoring_rules_kind_valid'
      remove_check_constraint :bolao_scoring_rules, name: 'bolao_scoring_rules_points_non_negative'
      remove_column :bolao_scoring_rules, :kind
      remove_column :bolao_scoring_rules, :points

      add_index :bolao_scoring_rules, %i[championship_id pool_id], unique: true, nulls_not_distinct: true
      add_index :bolao_scoring_rules, :pool_id
      add_foreign_key :bolao_scoring_rules, :core_championships, column: :championship_id
      add_check_constraint :bolao_scoring_rules, 'exact_score_points >= winner_points AND winner_points >= 0',
                           name: 'bolao_scoring_rules_bands_ordered'
      add_check_constraint :bolao_scoring_rules, 'pool_id IS NULL OR championship_id IS NULL',
                           name: 'bolao_scoring_rules_single_scope'
    end
  end

  def down
    safety_assured do
      remove_check_constraint :bolao_scoring_rules, name: 'bolao_scoring_rules_single_scope'
      remove_check_constraint :bolao_scoring_rules, name: 'bolao_scoring_rules_bands_ordered'
      remove_foreign_key :bolao_scoring_rules, column: :championship_id
      remove_index :bolao_scoring_rules, :pool_id
      remove_index :bolao_scoring_rules, %i[championship_id pool_id]
      execute 'DELETE FROM bolao_scoring_rules WHERE championship_id IS NOT NULL'

      add_column :bolao_scoring_rules, :kind, :string
      add_column :bolao_scoring_rules, :points, :integer
      split_rows
      change_column_null :bolao_scoring_rules, :kind, false
      change_column_null :bolao_scoring_rules, :points, false
      remove_column :bolao_scoring_rules, :exact_score_points
      remove_column :bolao_scoring_rules, :winner_points
      remove_column :bolao_scoring_rules, :championship_id

      add_index :bolao_scoring_rules, %i[pool_id kind], unique: true, nulls_not_distinct: true
      add_check_constraint :bolao_scoring_rules, 'points >= 0', name: 'bolao_scoring_rules_points_non_negative'
      add_check_constraint :bolao_scoring_rules, "kind IN ('exact_score','winner_and_goal_diff','winner','draw')",
                           name: 'bolao_scoring_rules_kind_valid'
    end
  end

  private

  def consolidate_rows
    execute <<~SQL.squish
      WITH bands AS (
        SELECT pool_id, MIN(id) AS keep_id,
               MAX(points) FILTER (WHERE kind = 'exact_score') AS exact_score,
               MAX(points) FILTER (WHERE kind = 'winner') AS winner
        FROM bolao_scoring_rules GROUP BY pool_id
      ), global AS (SELECT exact_score, winner FROM bands WHERE pool_id IS NULL)
      UPDATE bolao_scoring_rules rule
      SET exact_score_points = COALESCE(bands.exact_score, (SELECT exact_score FROM global), 10),
          winner_points = COALESCE(bands.winner, (SELECT winner FROM global), 5)
      FROM bands WHERE rule.id = bands.keep_id
    SQL
    execute 'DELETE FROM bolao_scoring_rules WHERE exact_score_points IS NULL'
    execute 'UPDATE bolao_scoring_rules SET winner_points = LEAST(winner_points, exact_score_points)'
  end

  def split_rows
    execute <<~SQL.squish
      INSERT INTO bolao_scoring_rules (pool_id, kind, points, exact_score_points, winner_points, created_at, updated_at)
      SELECT pool_id, band.kind, CASE band.kind WHEN 'exact_score' THEN exact_score_points ELSE winner_points END,
             exact_score_points, winner_points, created_at, updated_at
      FROM bolao_scoring_rules
      CROSS JOIN (VALUES ('exact_score'), ('winner_and_goal_diff'), ('winner'), ('draw')) AS band(kind)
    SQL
    execute 'DELETE FROM bolao_scoring_rules WHERE kind IS NULL'
  end
end
