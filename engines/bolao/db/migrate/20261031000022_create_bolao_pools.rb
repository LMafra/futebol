class CreateBolaoPools < ActiveRecord::Migration[8.1]
  def change
    create_table :bolao_pools do |t|
      t.references :championship, null: false, foreign_key: { to_table: :core_championships }
      t.references :owner, null: false, foreign_key: { to_table: :core_users }
      t.string :name, null: false

      t.timestamps
    end

    add_foreign_key :bolao_scoring_rules, :bolao_pools, column: :pool_id
  end
end
