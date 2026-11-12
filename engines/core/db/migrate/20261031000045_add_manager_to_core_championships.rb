class AddManagerToCoreChampionships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :core_championships, :manager_id, :bigint
    add_index :core_championships, :manager_id, algorithm: :concurrently
    add_foreign_key :core_championships, :core_users, column: :manager_id, validate: false
  end
end
