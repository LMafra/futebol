require 'rails_helper'

RSpec.describe Bolao::PredictionScore do
  it 'is unique per prediction and scoring_token' do
    score = create(:bolao_prediction_score)
    duplicate = build(:bolao_prediction_score, prediction: score.prediction, scoring_token: score.scoring_token)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(build(:bolao_prediction_score, prediction: score.prediction)).to be_valid
  end

  it 'rejects negative points in the database' do
    expect { create(:bolao_prediction_score).update_columns(points: -1) }
      .to raise_error(ActiveRecord::StatementInvalid, /bolao_prediction_scores_points_non_negative/)
  end

  it 'soft deletes with discard' do
    score = create(:bolao_prediction_score)

    score.discard

    expect(described_class.kept).to be_empty
    expect(described_class.with_discarded.count).to eq(1)
  end
end
