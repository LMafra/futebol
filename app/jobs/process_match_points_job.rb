class ProcessMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, scoring_token)
    match = Core::Match.find(match_id)
    return if match.scoring_token == scoring_token

    score!(match, scoring_token)
    BroadcastUpdateService.call(match:)
  rescue StandardError => e
    report_failure(e, match_id:, scoring_token:)
    raise
  end

  private

  def score!(match, scoring_token)
    Core::Match.transaction do
      rows = score_rows(match, scoring_token)
      Bolao::PredictionScore.insert_all(rows, unique_by: %i[prediction_id scoring_token]) if rows.any?
      match.mark_scored!(scoring_token)
    end
  end

  def report_failure(error, match_id:, scoring_token:)
    Rails.logger.error("ProcessMatchPointsJob failed match_id=#{match_id} scoring_token=#{scoring_token}: " \
                       "#{error.class} #{error.message}")
    Sentry.capture_exception(error, extra: { match_id:, scoring_token: })
  end

  def score_rows(match, scoring_token)
    rules_by_pool = Hash.new { |cache, pool| cache[pool] = Bolao::ScoringRule.for(pool) }
    now = Time.current

    Bolao::Prediction.kept.where(match:).includes(:pool).map do |prediction|
      points = Scoring::Engine.points_for(prediction:, home: match.home_score, away: match.away_score,
                                          rules: rules_by_pool[prediction.pool])
      { prediction_id: prediction.id, points:, scoring_token:, created_at: now, updated_at: now }
    end
  end
end
