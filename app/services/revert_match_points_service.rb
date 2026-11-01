class RevertMatchPointsService
  def self.call(match:, actor:, ip_address:, reversal_token: SecureRandom.uuid, reason: nil)
    new(match:, actor:, ip_address:, reversal_token:, reason:).call
  end

  def self.applied?(match, reversal_token)
    match.reversal_token == reversal_token ||
      Core::AuditLog.where(action: 'revert', auditable: match)
                    .exists?(["metadata ->> 'reversal_token' = ?", reversal_token])
  end

  def initialize(match:, actor:, ip_address:, reversal_token:, reason: nil)
    @match = match
    @actor = actor
    @ip_address = ip_address
    @reversal_token = reversal_token
    @reason = reason
  end

  # Returns false when this reversal_token was already applied (job retries, stale tokens).
  def call
    @match.with_lock do
      next false if self.class.applied?(@match, @reversal_token)

      scoring_token = @match.scoring_token
      @match.revert_match!(@reversal_token)
      discarded = Bolao::PredictionScore.kept.where(scoring_token:).discard_all
      audit!(scoring_token:, discarded_scores: discarded.size)
      true
    end
  end

  private

  def audit!(**metadata)
    Core::AuditLog.create!(action: 'revert', user: @actor, auditable: @match, ip_address: @ip_address,
                           metadata: metadata.merge(reversal_token: @reversal_token, reason: @reason).compact)
  end
end
