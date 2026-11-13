module Scouts
  # "Jogou" and "Destaque" of the single match page (ADR 0006): marked directly on Cartola::PlayerScore, without a
  # lance. One highlight per match; a player with no lance, unmarked as played and not the highlight leaves the
  # match. SG and points are scored again in the same transaction.
  class MarkParticipation
    Result = Data.define(:errors) do
      def success? = errors.empty?
    end

    def self.call(match:, player:, flags:, actor:, ip_address:)
      new(match, player).call(flags.slice(:played, :highlight), actor:, ip_address:)
    end

    def initialize(match, player)
      @match = match
      @player = player
    end

    def call(flags, actor:, ip_address:)
      errors = EventRules.match_errors(@match)
      return Result.new(errors:) if errors.any?

      @match.with_lock do
        mark!(flags)
        Cartola::RecordScoutsService.rescore!(@match)
        Core::AuditLog.create!(action: 'cartola.participation_marked', user: actor, auditable: @match, ip_address:,
                               metadata: { player_id: @player.id, **flags })
      end
      BroadcastUpdateService.call(match: @match) if @match.live?
      Result.new(errors: [])
    end

    private

    def mark!(flags)
      clear_highlight! if flags[:highlight]
      score = Cartola::PlayerScore.kept.find_or_initialize_by(match: @match, player: @player)
      score.assign_attributes(team_id: score.team_id || @player.team_id, points: score.points || 0, **flags)
      score.played ||= score.highlight
      leaves?(score) ? discard(score) : score.save!
    end

    def discard(score) = score.persisted? && score.discard!

    def leaves?(score)
      !score.played && !score.highlight && Cartola::PlayerScore::SCOUTS.all? { score.public_send(_1).zero? }
    end

    def clear_highlight!
      Cartola::PlayerScore.kept.where(match: @match, highlight: true).where.not(player: @player)
                          .update_all(highlight: false, updated_at: Time.current)
    end
  end
end
