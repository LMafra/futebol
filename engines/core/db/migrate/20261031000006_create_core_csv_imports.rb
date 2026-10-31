class CreateCoreCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :core_csv_imports do |t|
      t.string :status, null: false, default: 'pending'
      t.text :error_message
      t.integer :rows_processed, null: false, default: 0

      t.timestamps
    end
    add_check_constraint :core_csv_imports, "status IN ('pending','processing','completed','failed')",
                         name: 'csv_imports_status_valid'
    add_check_constraint :core_csv_imports, 'rows_processed >= 0', name: 'csv_imports_rows_non_negative'
  end
end
