module Scouts
  # The "−" of a player's stat (ADR 0006): discards the last kept lance of that player and stat (nothing is
  # deleted) and recounts the scouts in the same transaction. Broadcasts the match while it is live.
  class UndoLast
    Result = Data.define(:event, :errors) do
      def success? = errors.empty?
    end

    def self.call(match:, player:, stat:, actor:, ip_address:)
      new(match, player, stat).call(actor:, ip_address:)
    end

    def initialize(match, player, stat)
      @match = match
      @player = player
      @stat = stat.to_s
    end

    def call(actor:, ip_address:)
      last = Cartola::ScoutEvent.kept.where(match: @match, player: @player, stat: @stat).order(:id).last
      errors = EventRules.undo_errors(@match, last)
      return Result.new(event: last, errors:) if errors.any?

      undo!(last, actor, ip_address)
      BroadcastUpdateService.call(match: @match) if @match.live?
      Result.new(event: last, errors: [])
    end

    private

    def undo!(event, actor, ip_address)
      @match.with_lock do
        event.discard!
        Recount.call(@match, @player, event.team_id)
        Core::AuditLog.create!(action: 'cartola.scout_event_undone', user: actor, auditable: @match, ip_address:,
                               metadata: event.slice(:id, :player_id, :stat, :period, :minute))
      end
    end
  end
end
