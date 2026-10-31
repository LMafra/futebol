class CreateCoreSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :core_sessions do |t|
      t.references :user, null: false, foreign_key: { to_table: :core_users }
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
