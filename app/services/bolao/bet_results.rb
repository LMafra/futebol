module Bolao
  # One Result per prediction. Scored matches read the kept Bolao::PredictionScore; matches with a final score
  # that were not scored yet (finished, reverted) use the Bolao::CalculatePreviewService dry-run.
  class BetResults
    Result = Data.define(:prediction, :result, :points) do
      def pending? = result == :pending
    end

    def self.call(predictions) = new(predictions).call

    def initialize(predictions)
      @predictions = predictions.to_a
    end

    def call
      @predictions.map do |prediction|
        match = prediction.match
        next Result.new(prediction:, result: :pending, points: nil) if match.home_score.nil? || match.away_score.nil?

        Result.new(prediction:, result: result_for(prediction, match), points: points_for(prediction, match))
      end
    end

    private

    def result_for(prediction, match)
      Bolao::ScoringRule.result_for(prediction.home_guess, prediction.away_guess, match.home_score, match.away_score)
    end

    def points_for(prediction, match)
      return persisted_points.fetch(prediction.id, 0) if match.status == 'scored'

      preview_rows(match)[prediction.id]&.points || 0
    end

    def persisted_points
      @persisted_points ||= Bolao::PredictionScore.kept.where(prediction_id: @predictions.map(&:id))
                                                  .group(:prediction_id).sum(:points)
    end

    def preview_rows(match)
      @preview_rows ||= {}
      @preview_rows[match.id] ||= Bolao::CalculatePreviewService
                                  .call(match:, candidate_home: match.home_score, candidate_away: match.away_score)
                                  .rows.index_by(&:prediction_id)
    end
  end
end
