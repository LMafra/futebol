class AddRoleAndManagerStatusToCoreUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :core_users, :role, :integer, default: 0, null: false
    add_column :core_users, :manager_status, :integer, default: 0, null: false
    add_index :core_users, :role, algorithm: :concurrently
    add_index :core_users, :manager_status, algorithm: :concurrently
  end
end
