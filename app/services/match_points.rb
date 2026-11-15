# Pontuação of a match in the request that finishes, edits or reverts it (no queue), inside the caller's lock:
#   score!(match):   the Bolão points of every kept prediction and the Esquadrão player values under a new
#                    scoring_token; the match goes to scored;
#   unscore!(match): discards those points and puts the values back; the match goes to reverted.
module MatchPoints
  def self.score!(match, scoring_token = SecureRandom.uuid)
    rows = prediction_rows(match, scoring_token)
    Bolao::PredictionScore.insert_all(rows, unique_by: %i[prediction_id scoring_token]) if rows.any?
    match.mark_scored!(scoring_token)
    Cartola::ValueUpdate.call(match, scoring_token)
    scoring_token
  end

  # Returns how many prediction scores were discarded.
  def self.unscore!(match, reversal_token = SecureRandom.uuid)
    scoring_token = match.scoring_token
    match.revert_match!(reversal_token)
    discarded = Bolao::PredictionScore.kept.where(scoring_token:).discard_all.size
    Cartola::PlayerValue.revert!(scoring_token) if scoring_token
    discarded
  end

  def self.prediction_rows(match, scoring_token)
    predictions = Bolao::Prediction.kept.where(match:).includes(:pool).to_a
    rules_by_pool = Bolao::ScoringRule.by_pool(predictions.map(&:pool))
    now = Time.current
    predictions.map do |prediction|
      { prediction_id: prediction.id, points: points_for(prediction, rules_by_pool.fetch(prediction.pool_id), match),
        scoring_token:, created_at: now, updated_at: now }
    end
  end

  def self.points_for(prediction, rule, match)
    rule.points_for(prediction.home_guess, prediction.away_guess, match.home_score, match.away_score).fetch(:points)
  end
end
