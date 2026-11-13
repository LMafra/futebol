class AddManagerAndCaptainToCoreTeams < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :core_teams, :manager_id, :bigint
    add_column :core_teams, :captain_name, :string
    add_column :core_teams, :captain_phone, :string
    add_index :core_teams, :manager_id, algorithm: :concurrently
    add_foreign_key :core_teams, :core_users, column: :manager_id, validate: false
    # Short names repeat across managers once shared teams are copied; NULLS NOT DISTINCT keeps the admin's unique.
    add_index :core_teams, %i[manager_id short_name], unique: true, nulls_not_distinct: true,
                                                      algorithm: :concurrently
    remove_index :core_teams, :short_name, unique: true, algorithm: :concurrently
  end
end
