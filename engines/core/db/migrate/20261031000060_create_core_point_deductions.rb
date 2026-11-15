class CreateCorePointDeductions < ActiveRecord::Migration[8.1]
  def change
    create_table :core_point_deductions do |t|
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }, index: false
      t.references :team, null: false, foreign_key: { to_table: :core_teams }
      t.references :created_by, null: false, foreign_key: { to_table: :core_users }
      t.references :revoked_by, foreign_key: { to_table: :core_users }
      t.integer :points, null: false
      t.text :reason, null: false
      t.datetime :revoked_at

      t.timestamps

      t.index %i[championship_id team_id], where: 'revoked_at IS NULL', name: 'index_core_point_deductions_active'
      t.index :championship_id
      t.check_constraint 'points > 0', name: 'core_point_deductions_points'
      t.check_constraint "btrim(reason) <> ''", name: 'core_point_deductions_reason'
      t.check_constraint '(revoked_at IS NULL) = (revoked_by_id IS NULL)', name: 'core_point_deductions_revoked'
    end
  end
end
