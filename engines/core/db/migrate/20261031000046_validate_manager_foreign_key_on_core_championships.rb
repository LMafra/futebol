class ValidateManagerForeignKeyOnCoreChampionships < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :core_championships, :core_users, column: :manager_id
  end
end
