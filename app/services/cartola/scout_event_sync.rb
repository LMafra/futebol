module Cartola
  # Keeps the lances (Cartola::ScoutEvent) equal to the totals saved by the scout sheet (RecordScoutsService):
  # a total above the kept lances adds lances without period or minute; a total below them discards the latest
  # ones. Players who left the sheet lose all their lances.
  class ScoutEventSync
    def self.call(match, rows, actor) = new(match, actor).call(rows)

    def initialize(match, actor)
      @match = match
      @actor = actor
    end

    def call(rows)
      kept = kept_ids
      targets = rows.to_h { |row| [row.player_id, row] }
      discard!(kept.flat_map { |(player_id, stat), ids| ids.first(excess(ids, targets[player_id], stat)) })
      add!(rows.flat_map { |row| missing(row, kept) })
    end

    private

    # { [player_id, stat] => ids of the kept lances, newest first }
    def kept_ids
      ScoutEvent.kept.where(match: @match).order(id: :desc).pluck(:id, :player_id, :stat)
                .group_by { |_, player_id, stat| [player_id, stat] }
                .transform_values { |events| events.map(&:first) }
    end

    def excess(ids, row, stat) = [ids.size - (row ? row.count(stat.to_sym) : 0), 0].max

    def missing(row, kept)
      PlayerScore::SCOUTS.flat_map do |scout|
        count = row.count(scout) - kept.fetch([row.player_id, scout.to_s], []).size
        Array.new([count, 0].max) { { player_id: row.player_id, team_id: row.team_id, stat: scout.to_s } }
      end
    end

    def discard!(ids)
      now = Time.current
      ScoutEvent.where(id: ids).update_all(discarded_at: now, updated_at: now) if ids.any?
    end

    def add!(events)
      return if events.empty?

      ScoutEvent.insert_all(events.map { _1.merge(match_id: @match.id, recorded_by_id: @actor&.id) })
    end
  end
end
