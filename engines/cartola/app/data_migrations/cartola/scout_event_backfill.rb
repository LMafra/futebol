module Cartola
  # Lances for the scouts recorded before them (ADR 0006): one lance without period or minute per unit of each kept
  # counter, so the counters keep being the sum of the kept lances. Points don't change. Matches that already have
  # lances are skipped, so running it again adds nothing. Plain SQL, so it does not depend on the models.
  class ScoutEventBackfill
    STATS = %w[goals assists penalty_saves saves yellow_cards red_cards own_goals].freeze

    def initialize(connection)
      @connection = connection
    end

    def up
      @connection.execute(<<~SQL.squish)
        INSERT INTO cartola_scout_events (match_id, player_id, team_id, stat, created_at, updated_at)
        SELECT s.match_id, s.player_id, s.team_id, totals.stat, s.updated_at, s.updated_at
        FROM cartola_player_scores s
        CROSS JOIN LATERAL (VALUES #{STATS.map { "('#{_1}', s.#{_1})" }.join(', ')}) AS totals(stat, total)
        CROSS JOIN LATERAL generate_series(1, totals.total)
        WHERE s.discarded_at IS NULL AND totals.total > 0
          AND NOT EXISTS (SELECT 1 FROM cartola_scout_events e WHERE e.match_id = s.match_id)
      SQL
    end

    # Backfilled lances are the ones without period, minute or author.
    def down
      @connection.execute(<<~SQL.squish)
        DELETE FROM cartola_scout_events WHERE period IS NULL AND minute IS NULL AND recorded_by_id IS NULL
      SQL
    end
  end
end
