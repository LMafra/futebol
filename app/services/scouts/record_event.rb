module Scouts
  # Records a lance (ADR 0006): saves the Cartola::ScoutEvent and recounts the player's scouts in the same
  # transaction, starting a scheduled match whose kickoff has passed. Broadcasts the match while it is live.
  #   Scouts::RecordEvent.call(event: Cartola::ScoutEvent.new(match:, player:, stat: 'goals', period:, minute:),
  #                            actor:, ip_address:)
  class RecordEvent
    Result = Data.define(:event, :errors) do
      def success? = errors.empty?
    end

    def self.call(event:, actor:, ip_address:) = new(event, actor, ip_address).call

    def initialize(event, actor, ip_address)
      @event = event
      @event.team_id ||= event.player&.team_id
      @actor = actor
      @ip_address = ip_address
    end

    def call
      errors = EventRules.record_errors(@event)
      return Result.new(event: @event, errors:) if errors.any?

      record!
      BroadcastUpdateService.call(match: match) if match.live?
      Result.new(event: @event, errors: [])
    end

    private

    def match = @event.match

    def record!
      match.with_lock do
        match.start_match! if match.may_start_match?
        @event.update!(recorded_by: @actor)
        Recount.call(match, @event.player, @event.team_id)
        metadata = @event.slice(:id, :player_id, :stat, :period, :minute)
        Core::AuditLog.create!(action: 'cartola.scout_event_recorded', user: @actor, auditable: match,
                               ip_address: @ip_address, metadata:)
      end
    end
  end
end
