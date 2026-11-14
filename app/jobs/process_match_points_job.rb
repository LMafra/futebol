class ProcessMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, scoring_token)
    match = Core::Match.find(match_id)
    scored = match.with_lock { match.may_mark_scored? && MatchPoints.score!(match, scoring_token) }
    BroadcastUpdateService.call(match:) if scored
  end
end
