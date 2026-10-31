class RevertMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, reversal_token)
    # TODO: TICKET-0005
    raise NotImplementedError
  end
end
