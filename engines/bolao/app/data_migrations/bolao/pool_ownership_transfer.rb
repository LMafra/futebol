module Bolao
  # Bolões are created by the Gestor or the Admin (ADR 0006): each existing pool passes to the gestor of its
  # championship, and the old owner stays a member. Pools of championships without a gestor keep their owner.
  # Plain SQL, so it does not depend on the models at the time it runs.
  class PoolOwnershipTransfer
    def initialize(connection)
      @connection = connection
    end

    def up
      keep_owners_as_members
      transfer_to_managers
    end

    def keep_owners_as_members
      @connection.execute(<<~SQL.squish)
        INSERT INTO bolao_pool_memberships (pool_id, user_id, joined_at, created_at, updated_at)
        SELECT p.id, p.owner_id, p.created_at, NOW(), NOW()
        FROM bolao_pools p
        JOIN core_championships c ON c.id = p.championship_id
        WHERE c.manager_id IS NOT NULL AND p.owner_id <> c.manager_id
        ON CONFLICT (pool_id, user_id) DO NOTHING
      SQL
    end

    def transfer_to_managers
      @connection.execute(<<~SQL.squish)
        UPDATE bolao_pools p SET owner_id = c.manager_id, updated_at = NOW()
        FROM core_championships c
        WHERE c.id = p.championship_id AND c.manager_id IS NOT NULL AND p.owner_id <> c.manager_id
      SQL
    end

    # The old owner joined first (a pool used to add its creator as a member), so the earliest member who is not
    # the gestor gets the pool back.
    def down
      @connection.execute(<<~SQL.squish)
        UPDATE bolao_pools p SET owner_id = (
          SELECT m.user_id FROM bolao_pool_memberships m
          WHERE m.pool_id = p.id AND m.user_id <> c.manager_id
          ORDER BY m.joined_at, m.id LIMIT 1
        ), updated_at = NOW()
        FROM core_championships c
        WHERE c.id = p.championship_id AND p.owner_id = c.manager_id
          AND EXISTS (SELECT 1 FROM bolao_pool_memberships m WHERE m.pool_id = p.id AND m.user_id <> c.manager_id)
      SQL
    end
  end
end
