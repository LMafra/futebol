class AddProfileAndLgpdFieldsToCoreUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :core_users, bulk: true do |t|
      t.string :name
      t.string :cpf
      t.boolean :active, null: false, default: true
      t.datetime :anonymized_at
    end
    add_index :core_users, :cpf, unique: true, where: 'cpf IS NOT NULL'
    add_check_constraint :core_users, "cpf IS NULL OR cpf ~ '^[0-9]{11}$'", name: 'core_users_cpf_digits'
    add_check_constraint :core_users, 'anonymized_at IS NULL OR (NOT active AND cpf IS NULL)',
                         name: 'core_users_anonymized_inactive'
  end
end
