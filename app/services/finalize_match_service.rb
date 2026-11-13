class FinalizeMatchService
  def self.call(match:, home_score:, away_score:, actor:, ip_address:)
    new(match:, home_score:, away_score:, actor:, ip_address:).call
  end

  def initialize(match:, home_score:, away_score:, actor:, ip_address:)
    @match = match
    @home_score = home_score
    @away_score = away_score
    @actor = actor
    @ip_address = ip_address
  end

  # Records the final score through AASM (scheduled → live → finished), recomputes the scouts' SG and points with
  # the rule in force, audits it and enqueues the scoring once the transaction has committed.
  def call
    @match.with_lock { finish! }
    ProcessMatchPointsJob.perform_later(@match.id, SecureRandom.uuid)
    BroadcastUpdateService.call(match: @match)
    @match
  end

  private

  def finish!
    Cartola::RecordScoutsService.rescore!(@match)
    @match.assign_attributes(home_score: @home_score, away_score: @away_score)
    @match.start_match! if @match.may_start_match?
    @match.finish_match!
    Core::AuditLog.create!(action: 'finalize', user: @actor, auditable: @match, ip_address: @ip_address,
                           metadata: { home_score: @home_score, away_score: @away_score })
  end
end
