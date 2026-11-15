class FinalizeMatchService
  # Statuses a match can be finalized from: live (or scheduled with the kickoff passed); finished and reverted
  # are matches still without points (scored by a queue before, or reverted).
  FINALIZABLE = %w[live finished reverted].freeze

  def self.call(match:, home_score:, away_score:, actor:, ip_address:)
    new(match:, home_score:, away_score:, actor:, ip_address:).call
  end

  def self.finalizable?(match) = match.status.in?(FINALIZABLE) || match.may_start_match?

  def initialize(match:, home_score:, away_score:, actor:, ip_address:)
    @match = match
    @home_score = home_score
    @away_score = away_score
    @actor = actor
    @ip_address = ip_address
  end

  # Records the final score through AASM (scheduled → live → finished → scored), recomputes the scouts' SG and
  # points with the rule in force and scores the Bolão and the Esquadrão values in the same transaction (MatchPoints),
  # then audits it.
  def call
    @match.with_lock { finish! }
    BroadcastUpdateService.call(match: @match)
    @match
  end

  private

  def finish!
    Cartola::RecordScoutsService.rescore!(@match)
    @match.assign_attributes(home_score: @home_score, away_score: @away_score)
    @match.start_match! if @match.may_start_match?
    @match.finish_match! if @match.live?
    scoring_token = MatchPoints.score!(@match)
    Core::AuditLog.create!(action: 'finalize', user: @actor, auditable: @match, ip_address: @ip_address,
                           metadata: { home_score: @home_score, away_score: @away_score, scoring_token: })
  end
end
