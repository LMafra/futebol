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
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
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

  it 'stores the 2-band points (10 exact / 5 winner or draw / 0) and marks the match scored' do
    perform

    expect(predictions.map { |prediction| Bolao::PredictionScore.find_by!(prediction:).points }).to eq([10, 5, 0, 0])
    expect(match.reload).to have_attributes(status: 'scored', scoring_token: token)
    expect(match.scores_calculated_at).to be_present
  end

  it 'broadcasts the updated scoreboard once, after scoring' do
    expect { 2.times { perform } }.to have_broadcasted_to(match.to_gid_param).once
  end

  it 'uses pool overrides of the scoring rules' do
    create(:bolao_scoring_rule, pool_id: pool.id, exact_score_points: 20, winner_points: 8)

    perform

    expect(Bolao::PredictionScore.find_by!(prediction: predictions.first).points).to eq(20)
    expect(Bolao::PredictionScore.find_by!(prediction: predictions.second).points).to eq(8)
  end

  it 'uses the championship rule when the pool has no override' do
    create(:bolao_scoring_rule, championship: pool.championship, exact_score_points: 12, winner_points: 6)

    perform

    expect(predictions.map { |prediction| Bolao::PredictionScore.find_by!(prediction:).points }).to eq([12, 6, 0, 0])
  end

  it 'ignores discarded predictions' do
    predictions.last.discard

    expect { perform }.to change(Bolao::PredictionScore, :count).by(predictions.size - 1)
  end

  describe 'failure handling (rescue)' do
    before do
      allow(Rails.logger).to receive(:error).and_call_original
      allow(Bolao::ScoringRule).to receive(:by_pool).and_raise(RuntimeError, 'engine exploded')
    end

    it 'logs the error, reports it as an OTel error span and re-raises' do
      expect { perform }.to raise_error(RuntimeError, 'engine exploded')

      expect(Rails.logger).to have_received(:error)
        .with(/ProcessMatchPointsJob failed match_id=#{match.id} scoring_token=#{token}: RuntimeError engine exploded/)
      expect(error_spans(RuntimeError).sole.attributes)
        .to include('exception.message' => 'engine exploded', 'exception.handled' => false,
                    'error.context.match_id' => match.id, 'error.context.scoring_token' => token)
    end

    it 'leaves no partial scores and keeps the match unscored' do
      expect { perform }.to raise_error(RuntimeError)

      expect(Bolao::PredictionScore.count).to eq(0)
      expect(match.reload).to have_attributes(status: 'finished', scoring_token: nil, scores_calculated_at: nil)
    end
  end

  it 'refuses to score a match that is not finished, rolling back the inserted scores' do
    match.update!(status: 'live')

    expect { perform }.to raise_error(AASM::InvalidTransition)
    expect(Bolao::PredictionScore.count).to eq(0)
  end
end
