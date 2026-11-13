module Core
  # Gives every team to the manager of the championships it plays in and enrolls it in them (ADR 0006).
  # A team that plays for several managers stays with the one it has most matches for; every other manager (or
  # the admin, for championships without a manager) gets a copy with the players, and that manager's matches,
  # scouts, player values and lineups move to the copy. Teams without matches stay with the admin.
  # Copies are marked by the external id suffix, which is how #down merges them back. Plain SQL with the column
  # lists read from the database, so it does not depend on the models of later versions.
  class TeamOwnershipBackfill
    COPY_MARK = '~gestor-'.freeze
    ALL_CHAMPIONSHIPS = 'SELECT id FROM core_championships'.freeze
    # Tables pointing at players, each narrowed to some championships (%s is a subquery of their ids).
    PLAYER_REFERENCES = {
      'cartola_player_scores' => 'match_id IN (SELECT id FROM core_matches WHERE championship_id IN (%s))',
      'cartola_lineup_players' => 'lineup_id IN (SELECT id FROM cartola_lineups WHERE championship_id IN (%s))',
      'cartola_player_values' => 'championship_id IN (%s)',
      'cartola_player_value_histories' => 'championship_id IN (%s)'
    }.freeze

    def initialize(connection = ActiveRecord::Base.connection)
      @connection = connection
    end

    def up
      connection.select_values('SELECT id FROM core_teams ORDER BY id').each { |team_id| assign(team_id) }
      enroll
    end

    def down
      execute('DELETE FROM core_championship_teams')
      connection.select_rows("SELECT id, external_id FROM core_teams WHERE external_id LIKE '%#{COPY_MARK}%'")
                .each { |copy_id, external_id| merge(copy_id, *external_id.split(COPY_MARK, 2)) }
      execute('UPDATE core_teams SET manager_id = NULL')
    end

    private

    attr_reader :connection

    def execute(sql) = connection.execute(sql)
    def quote(value) = connection.quote(value)

    def assign(team_id)
      owner, *others = owners(team_id)
      execute("UPDATE core_teams SET manager_id = #{quote(owner)} WHERE id = #{team_id}")
      others.each { |manager_id| split(team_id, manager_id) }
    end

    # Managers of the championships the team plays in, most matches first; nil is the admin.
    def owners(team_id)
      connection.select_values(<<~SQL.squish)
        SELECT c.manager_id FROM core_matches m JOIN core_championships c ON c.id = m.championship_id
        WHERE #{team_id} IN (m.home_team_id, m.away_team_id)
        GROUP BY c.manager_id ORDER BY count(*) DESC, c.manager_id NULLS LAST
      SQL
    end

    def split(team_id, manager_id)
      suffix = quote("#{COPY_MARK}#{manager_id || 'admin'}")
      copy_id = copy_team(team_id, manager_id, suffix)
      copy_players(team_id, copy_id, suffix)
      pairs = player_pairs(team_id, copy_id, "o.external_id = f.external_id || #{suffix}")
      repoint(team_id, copy_id, pairs,
              "#{ALL_CHAMPIONSHIPS} WHERE manager_id IS NOT DISTINCT FROM #{quote(manager_id)}")
    end

    def copy_team(team_id, manager_id, suffix)
      columns = copied_columns('core_teams', 'manager_id')
      connection.select_value(<<~SQL.squish)
        INSERT INTO core_teams (#{columns}, manager_id, external_id, created_at, updated_at)
        SELECT #{columns}, #{quote(manager_id)}, external_id || #{suffix}, now(), now()
        FROM core_teams WHERE id = #{team_id} RETURNING id
      SQL
    end

    def copy_players(team_id, copy_id, suffix)
      columns = copied_columns('core_players', 'team_id')
      execute(<<~SQL.squish)
        INSERT INTO core_players (#{columns}, team_id, external_id, created_at, updated_at)
        SELECT #{columns}, #{copy_id}, external_id || #{suffix}, now(), now() FROM core_players WHERE team_id = #{team_id}
      SQL
    end

    def copied_columns(table, owner_column)
      (connection.columns(table).map(&:name) - ['id', 'external_id', 'created_at', 'updated_at', owner_column])
        .join(', ')
    end

    # Players of one team (f) paired with those of the other (o) by external id.
    def player_pairs(from, to, condition)
      <<~SQL.squish
        SELECT f.id AS from_id, o.id AS to_id FROM core_players f JOIN core_players o ON #{condition}
        WHERE f.team_id = #{from} AND o.team_id = #{to}
      SQL
    end

    # Moves the matches, scouts, values and lineups of the given championships from one team to the other.
    def repoint(from, to, pairs, championships)
      %w[home_team_id away_team_id].each do |column|
        execute("UPDATE core_matches SET #{column} = #{to} " \
                "WHERE #{column} = #{from} AND championship_id IN (#{championships})")
      end
      execute("UPDATE cartola_player_scores SET team_id = #{to} WHERE team_id = #{from} " \
              "AND #{format(PLAYER_REFERENCES['cartola_player_scores'], championships)}")
      PLAYER_REFERENCES.each do |table, condition|
        execute("UPDATE #{table} t SET player_id = pairs.to_id FROM (#{pairs}) pairs " \
                "WHERE t.player_id = pairs.from_id AND #{format(condition, championships)}")
      end
    end

    # Players added to the copy after the split join the original without a shirt number, which may be taken.
    def merge(copy_id, original, owner)
      original_id = connection.select_value("SELECT id FROM core_teams WHERE external_id = #{quote(original)}")
      pairs = player_pairs(copy_id, original_id, "f.external_id = o.external_id || #{quote("#{COPY_MARK}#{owner}")}")
      repoint(copy_id, original_id, pairs, ALL_CHAMPIONSHIPS)
      execute("DELETE FROM core_players WHERE id IN (SELECT from_id FROM (#{pairs}) pairs)")
      execute("UPDATE core_players SET team_id = #{original_id}, shirt_number = NULL WHERE team_id = #{copy_id}")
      execute("DELETE FROM core_teams WHERE id = #{copy_id}")
    end

    def enroll
      execute(<<~SQL.squish)
        INSERT INTO core_championship_teams (championship_id, team_id, created_at, updated_at)
        SELECT DISTINCT championship_id, team_id, now(), now() FROM (
          SELECT championship_id, home_team_id AS team_id FROM core_matches
          UNION SELECT championship_id, away_team_id FROM core_matches
        ) played
        ON CONFLICT DO NOTHING
      SQL
    end
  end
end
