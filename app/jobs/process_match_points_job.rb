class ProcessMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, scoring_token)
    # TODO: TICKET-0004
    raise NotImplementedError
  end
end
