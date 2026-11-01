class RevertMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, reversal_token, ip_address:, actor_id: nil)
    match = Core::Match.find(match_id)
    return if match.reversal_token == reversal_token

    actor = Core::User.find(actor_id) if actor_id
    RevertMatchPointsService.call(match:, actor:, ip_address:, reversal_token:)
  rescue StandardError => e
    report_failure(e, match_id:, reversal_token:)
    raise
  end

  private

  def report_failure(error, match_id:, reversal_token:)
    Rails.logger.error("RevertMatchPointsJob failed match_id=#{match_id} reversal_token=#{reversal_token}: " \
                       "#{error.class} #{error.message}")
    Sentry.capture_exception(error, extra: { match_id:, reversal_token: })
  end
end
