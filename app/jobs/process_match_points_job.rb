class ProcessMatchPointsJob < ApplicationJob
  queue_as :default

  def perform(match_id, scoring_token)
    match = Core::Match.find(match_id)
    return if match.scoring_token == scoring_token

    score!(match, scoring_token)
    Cartola::ValueUpdateJob.perform_later(match.id, scoring_token)
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
    Rails.error.report(error, handled: false, context: { match_id:, scoring_token: })
  end

  def score_rows(match, scoring_token)
    predictions = Bolao::Prediction.kept.where(match:).includes(:pool).to_a
    rules_by_pool = Bolao::ScoringRule.by_pool(predictions.map(&:pool))
    now = Time.current

    predictions.map do |prediction|
      points = points_for(rules_by_pool.fetch(prediction.pool_id), prediction, match)
      { prediction_id: prediction.id, points:, scoring_token:, created_at: now, updated_at: now }
    end
  end

  def points_for(rule, prediction, match)
    rule.points_for(prediction.home_guess, prediction.away_guess, match.home_score, match.away_score).fetch(:points)
  end
end
