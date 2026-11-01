class CreateCoreUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :core_users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.boolean :admin, null: false, default: false

      t.timestamps
    end
    add_index :core_users, :email_address, unique: true
  end
end
