module Bolao
  # Participantes › Bolão: the organizer fixes a member's prediction, even after the match started, with the reason
  # in the AuditLog. If the match was already scored, the prediction gets its points again from the pool's rule
  # (Bolao::ScoringRule#points_for, as in ProcessMatchPointsJob) under the match's scoring token.
  class PredictionCorrection
    def self.call(prediction:, guess:, reason:, actor:, ip_address:)
      home_guess, away_guess = guess
      new(prediction, actor:, ip_address:).call(home_guess:, away_guess:, reason:)
    end

    def initialize(prediction, actor:, ip_address:)
      @prediction = prediction
      @actor = actor
      @ip_address = ip_address
    end

    def call(home_guess:, away_guess:, reason:)
      before = { home_guess: @prediction.home_guess, away_guess: @prediction.away_guess }
      Bolao::Prediction.transaction do
        @prediction.assign_attributes(home_guess:, away_guess:)
        @prediction.save!(context: :correction)
        points = rescore!
        audit!(before:, reason:, points:)
      end
    end

    private

    def rescore!
      match = @prediction.match
      return unless match.scored? && match.scoring_token

      points = points_for(match)
      @prediction.scores.find_or_initialize_by(scoring_token: match.scoring_token).update!(points:, discarded_at: nil)
      points
    end

    def points_for(match)
      rule = Bolao::ScoringRule.by_pool([@prediction.pool]).fetch(@prediction.pool_id)
      rule.points_for(@prediction.home_guess, @prediction.away_guess, match.home_score, match.away_score)
          .fetch(:points)
    end

    def audit!(before:, reason:, points:)
      after = { home_guess: @prediction.home_guess, away_guess: @prediction.away_guess }
      Core::AuditLog.create!(action: 'bolao.prediction_corrected', user: @actor, auditable: @prediction.pool,
                             ip_address: @ip_address,
                             metadata: { prediction_id: @prediction.id, user_id: @prediction.user_id,
                                         match_id: @prediction.match_id, before:, after:, reason:, points: }.compact)
    end
  end
end
