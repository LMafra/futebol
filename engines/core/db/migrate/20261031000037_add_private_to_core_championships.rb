class AddPrivateToCoreChampionships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :core_championships, :private, :boolean, default: false, null: false
    add_index :core_championships, :private, algorithm: :concurrently
  end
end
