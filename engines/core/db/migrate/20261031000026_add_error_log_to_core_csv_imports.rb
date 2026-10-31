class AddErrorLogToCoreCsvImports < ActiveRecord::Migration[8.1]
  def change
    add_column :core_csv_imports, :error_log, :text
    add_check_constraint :core_csv_imports,
                         "status <> 'failed' OR (error_message IS NOT NULL AND error_log IS NOT NULL)",
                         name: 'csv_imports_failed_has_error'
  end
end
