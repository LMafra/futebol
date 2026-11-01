module Cartola
  # Records the official scouts of a match (admin "Scouts da partida").
  #   rows: [{ player_id:, team_id:, goals:, assists:, penalty_saves:, saves:, yellow_cards:, red_cards:, own_goals:,
  #            played:, highlight: }]; form strings are accepted and blanks count as 0/false.
  # Only participants keep a row ("Jogou", a scout or "Destaque"); the others lose theirs. SG and points are
  # derived for every row with the rule in force; the score follows the scouts (a side's goals plus the other
  # side's own goals) and goes to the scoreboard while the match is live. A scheduled match whose kickoff has
  # passed starts here, as it would on the finalizer.
  class RecordScoutsService
    Result = Data.define(:errors) do
      def success? = errors.empty?
    end

    Row = Data.define(:player_id, :team_id, :scouts, :played, :highlight) do
      def participant? = played || highlight || scouts.values.any? { |value| value.to_i.positive? }
      def count(scout) = scouts.fetch(scout).to_i
    end

    def self.call(match:, rows:, actor:, ip_address:) = new(match).record(rows, actor:, ip_address:)

    # Finalization: SG and points of the kept scouts again, with the rule in force.
    def self.rescore!(match) = new(match).rescore!

    def initialize(match)
      @match = match
    end

    def record(raw_rows, actor:, ip_address:)
      rows = raw_rows.map { |raw| parse(raw) }
      errors = ScoutSheetValidator.errors(@match, rows)
      return Result.new(errors:) if errors.any?

      save!(rows.select(&:participant?), actor:, ip_address:)
      BroadcastUpdateService.call(match: @match) if @match.live?
      Result.new(errors: [])
    end

    def rescore!
      rows = PlayerScore.kept.where(match: @match).map do |player_score|
        Row.new(player_id: player_score.player_id, team_id: player_score.team_id,
                scouts: player_score.stats.slice(*PlayerScore::SCOUTS), played: player_score.played,
                highlight: player_score.highlight)
      end
      persist!(rows) if rows.any?
    end

    private

    def parse(raw)
      Row.new(player_id: raw[:player_id].to_i, team_id: raw[:team_id].to_i,
              scouts: PlayerScore::SCOUTS.to_h { |scout| [scout, integer(raw[scout])] },
              played: boolean(raw[:played]), highlight: boolean(raw[:highlight]))
    end

    def integer(value) = value.blank? ? 0 : Integer(value.to_s, 10, exception: false)

    def boolean(value) = ActiveModel::Type::Boolean.new.cast(value) || false

    def save!(participants, actor:, ip_address:)
      @match.with_lock do
        @match.start_match! if @match.may_start_match?
        persist!(participants)
        home_score, away_score = score(participants)
        @match.update!(home_score:, away_score:) if @match.live?
        audit!(actor, ip_address, home_score:, away_score:, participants: participants.size)
      end
    end

    def score(rows)
      by_team = rows.group_by(&:team_id).transform_values do |team_rows|
        %i[goals own_goals].map { |scout| team_rows.sum { |row| row.count(scout) } }
      end
      PlayerScore.final_score(@match, by_team)
    end

    def persist!(rows)
      release!(rows)
      return if rows.empty?

      rule = ScoringRule.default
      home_score, away_score = score(rows)
      conceded = { @match.home_team_id => away_score, @match.away_team_id => home_score }
      PlayerScore.upsert_all(rows.map { |row| attributes_for(row, rule, conceded) },
                             unique_by: :index_cartola_player_scores_kept_unique)
    end

    # Discards the rows of players who no longer take part and clears the highlight before the upsert sets it.
    def release!(rows)
      kept = PlayerScore.kept.where(match: @match)
      now = Time.current
      kept.where.not(player_id: rows.map(&:player_id)).update_all(discarded_at: now, updated_at: now)
      kept.where(highlight: true).update_all(highlight: false, updated_at: now)
    end

    def attributes_for(row, rule, conceded)
      stats = row.scouts.merge(played: row.played, highlight: row.highlight,
                               clean_sheet: row.played && conceded.fetch(row.team_id).zero?)
      { player_id: row.player_id, match_id: @match.id, team_id: row.team_id, **stats,
        points: Scorer.points(stats:, rules: rule) }
    end

    def audit!(actor, ip_address, **metadata)
      Core::AuditLog.create!(action: 'cartola.scouts_recorded', user: actor, auditable: @match, ip_address:,
                             metadata:)
    end
  end
end
