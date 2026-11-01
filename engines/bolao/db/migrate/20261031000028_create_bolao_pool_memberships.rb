class CreateBolaoPoolMemberships < ActiveRecord::Migration[8.1]
  def up
    create_table :bolao_pool_memberships do |t|
      t.references :pool, null: false, foreign_key: { to_table: :bolao_pools }
      t.references :user, null: false, foreign_key: { to_table: :core_users }
      t.datetime :joined_at, null: false

      t.timestamps
    end
    add_index :bolao_pool_memberships, %i[pool_id user_id], unique: true

    execute <<~SQL.squish
      INSERT INTO bolao_pool_memberships (pool_id, user_id, joined_at, created_at, updated_at)
      SELECT id, owner_id, created_at, NOW(), NOW() FROM bolao_pools
    SQL
  end

  def down
    drop_table :bolao_pool_memberships
  end
end
