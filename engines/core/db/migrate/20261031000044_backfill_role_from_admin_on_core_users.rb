class BackfillRoleFromAdminOnCoreUsers < ActiveRecord::Migration[8.1]
  def up
    safety_assured { execute 'UPDATE core_users SET role = 2 WHERE admin = true' }
  end

  def down
    # no-op: demoting admins on rollback would lose the boolean source of truth
  end
end
