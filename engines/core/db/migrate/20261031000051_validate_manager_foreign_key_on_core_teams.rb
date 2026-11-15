class ValidateManagerForeignKeyOnCoreTeams < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :core_teams, :core_users, column: :manager_id
  end
end
