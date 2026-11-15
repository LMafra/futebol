module Cartola
  # Kept for jobs enqueued before the scoring moved into the request: Cartola::ValueUpdate does the work.
  class ValueUpdateJob < ApplicationJob
    queue_as :default

    def perform(match_id, scoring_token) = ValueUpdate.call(Core::Match.find(match_id), scoring_token)
  end
end
