# The trailing broadcast of BroadcastUpdateService: sends the match page as it is at the end of the throttle window.
class MatchBroadcastJob < ApplicationJob
  queue_as :default

  def perform(match_id)
    match = Core::Match.find_by(id: match_id)
    BroadcastUpdateService.new(match).broadcast! if match
  end
end
