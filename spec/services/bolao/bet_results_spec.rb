require 'rails_helper'

RSpec.describe Bolao::BetResults do
  let(:pool) { create(:bolao_pool) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
  end

  def bet(match, home, away) = create(:bolao_prediction, pool:, match:, home_guess: home, away_guess: away)

  def summary(predictions) = described_class.call(predictions).map { |result| [result.result, result.points] }

  it 'is pending while the match has no final score' do
    expect(summary([bet(create(:match), 1, 0)])).to eq([[:pending, nil]])
  end

  it 'previews points for a finished match that was not scored yet, without writing' do
    match = create(:match, status: 'finished', home_score: 2, away_score: 1)
    predictions = [bet(match, 2, 1), bet(match, 3, 2), bet(match, 1, 1)]

    expect { expect(summary(predictions)).to eq([[:exact, 10], [:winner, 5], [:miss, 0]]) }
      .not_to change(Bolao::PredictionScore, :count)
  end

  it 'reads the persisted kept scores of a scored match' do
    match = create(:match, status: 'finished', home_score: 0, away_score: 0, match_date: 1.day.ago)
    predictions = [bet(match, 0, 0), bet(match, 1, 1), bet(match, 2, 0)]
    ProcessMatchPointsJob.perform_now(match.id, SecureRandom.uuid)

    expect(match.reload).to be_scored
    expect(summary(predictions.map(&:reload))).to eq([[:exact, 10], [:winner, 5], [:miss, 0]])
  end
end
