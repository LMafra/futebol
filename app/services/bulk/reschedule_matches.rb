module Bulk
  # Shifts the kickoff of scheduled matches by the same amount (days or hours), with the reason in the AuditLog.
  # Matches that already started are kept.
  class RescheduleMatches
    def self.call(matches, shift:, reason:, actor:, ip_address:)
      new(matches, shift:, reason:, actor:, ip_address:).call
    end

    def initialize(matches, shift:, reason:, actor:, ip_address:)
      @matches = matches
      @shift = shift
      @reason = reason
      @actor = actor
      @ip_address = ip_address
      @report = Report.new(done: %w[reagendada reagendadas], kept: %w[mantida mantidas])
    end

    def call
      Bulk.one_by_one do
        @matches.each do |match|
          match.scheduled? ? reschedule(match) : @report.keep!(match, ['não está agendada', 'não estão agendadas'])
        end
      end
      @report
    end

    private

    def reschedule(match)
      from = match.match_date
      match.transaction do
        match.update!(match_date: from + @shift)
        ::Core::AuditLog.create!(action: 'match.rescheduled', user: @actor, auditable: match, ip_address: @ip_address,
                                 metadata: { reason: @reason, from: from.iso8601, to: match.match_date.iso8601 })
      end
      @report.done!(match)
    end
  end
end
