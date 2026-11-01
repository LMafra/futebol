class CreateCoreAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :core_audit_logs do |t|
      t.references :user, foreign_key: { to_table: :core_users }
      t.string :action, null: false
      t.references :auditable, polymorphic: true
      t.inet :ip_address, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :core_audit_logs, :action
  end
end
