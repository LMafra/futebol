module Bolao
  # Dry-run: scores the match predictions against a candidate result handed in by the caller,
  # never against the match's real score, and writes nothing.
  class CalculatePreviewService
    def self.call(match:, candidate_home:, candidate_away:, scorer: Bolao.scorer)
      new(match:, home: candidate(candidate_home, :candidate_home), away: candidate(candidate_away, :candidate_away),
          scorer:).call
    end

    def self.candidate(value, name)
      goals = Integer(value.to_s, 10, exception: false)
      return goals if goals && !goals.negative?

      raise ArgumentError, "#{name} must be an integer >= 0 (got #{value.inspect})"
    end
    private_class_method :candidate

    def initialize(match:, home:, away:, scorer:)
      @match = match
      @home = home
      @away = away
      @scorer = scorer
    end

    def call
      predictions = Prediction.kept.where(match: @match).includes(:pool).order(:id).to_a
      rules_by_pool = ScoringRule.by_pool(predictions.map(&:pool_id))
      rows = predictions.map { |prediction| row_for(prediction, rules_by_pool.fetch(prediction.pool_id)) }.freeze

      Preview.new(rows:, total: rows.sum(&:points))
    end

    private

    def row_for(prediction, rules)
      Preview::Row.new(
        prediction_id: prediction.id, pool_id: prediction.pool_id, user_id: prediction.user_id,
        home_guess: prediction.home_guess, away_guess: prediction.away_guess,
        points: @scorer.points_for(prediction:, home: @home, away: @away, rules:)
      )
    end
  end
end
