require 'rails_helper'

RSpec.describe ProcessMatchPointsJob do
  let(:match) { create(:match, status: 'finished', home_score: 2, away_score: 1, match_date: 1.day.ago) }
  let(:pool) { create(:bolao_pool) }
  let(:token) { SecureRandom.uuid }
  let!(:predictions) do
    [[2, 1], [3, 2], [1, 1], [0, 1]].map do |home_guess, away_guess|
      create(:bolao_prediction, pool:, match:, home_guess:, away_guess:)
    end
  end

  before do
    { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 }.each do |kind, points|
      create(:bolao_scoring_rule, pool_id: nil, kind:, points:)
    end
  end

  def perform = described_class.perform_now(match.id, token)

  describe 'idempotency by scoring_token' do
    it 'scores the predictions once: a second run with the same match and token is a no-op' do
      expect { 2.times { perform } }.to change(Bolao::PredictionScore, :count).by(predictions.size)
      expect(Bolao::PredictionScore.pluck(:scoring_token).uniq).to eq([token])
    end

    it 'does not touch the match on the second run' do
      perform
      scored_at = match.reload.scores_calculated_at

      expect { perform }.not_to(change { match.reload.attributes })
      expect(match.scores_calculated_at).to eq(scored_at)
    end
  end

  it 'stores each prediction points with the Bolão rules (10/7/3/0) and marks the match scored' do
    perform

    expect(predictions.map { |prediction| Bolao::PredictionScore.find_by!(prediction:).points }).to eq([10, 7, 0, 0])
    expect(match.reload).to have_attributes(status: 'scored', scoring_token: token)
    expect(match.scores_calculated_at).to be_present
  end

  it 'uses pool overrides of the scoring rules' do
    create(:bolao_scoring_rule, pool_id: pool.id, kind: 'exact_score', points: 20)

    perform

    expect(Bolao::PredictionScore.find_by!(prediction: predictions.first).points).to eq(20)
  end

  it 'ignores discarded predictions' do
    predictions.last.discard

    expect { perform }.to change(Bolao::PredictionScore, :count).by(predictions.size - 1)
  end

  describe 'failure handling (rescue)' do
    before do
      allow(Sentry).to receive(:capture_exception)
      allow(Rails.logger).to receive(:error).and_call_original
      allow(Scoring::Engine).to receive(:points_for).and_raise(RuntimeError, 'engine exploded')
    end

    it 'logs the error, reports it to Sentry and re-raises' do
      expect { perform }.to raise_error(RuntimeError, 'engine exploded')

      expect(Rails.logger).to have_received(:error)
        .with(/ProcessMatchPointsJob failed match_id=#{match.id} scoring_token=#{token}: RuntimeError engine exploded/)
      expect(Sentry).to have_received(:capture_exception)
        .with(an_instance_of(RuntimeError), hash_including(extra: { match_id: match.id, scoring_token: token }))
    end

    it 'leaves no partial scores and keeps the match unscored' do
      expect { perform }.to raise_error(RuntimeError)

      expect(Bolao::PredictionScore.count).to eq(0)
      expect(match.reload).to have_attributes(status: 'finished', scoring_token: nil, scores_calculated_at: nil)
    end
  end

  it 'refuses to score a match that is not finished, rolling back the inserted scores' do
    allow(Sentry).to receive(:capture_exception)
    match.update!(status: 'live')

    expect { perform }.to raise_error(AASM::InvalidTransition)
    expect(Bolao::PredictionScore.count).to eq(0)
  end
end
