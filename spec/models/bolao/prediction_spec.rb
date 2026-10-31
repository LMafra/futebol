require 'rails_helper'

RSpec.describe Bolao::Prediction do
  it 'belongs to a pool, a user and a match' do
    prediction = create(:bolao_prediction)

    expect(prediction.reload).to have_attributes(pool: be_a(Bolao::Pool), user: be_a(Core::User),
                                                 match: be_a(Core::Match))
  end

  it 'rejects negative guesses, in the model and in the database' do
    expect(build(:bolao_prediction, home_guess: -1)).not_to be_valid

    expect { create(:bolao_prediction).update_columns(away_guess: -1) }
      .to raise_error(ActiveRecord::StatementInvalid, /bolao_predictions_guesses_non_negative/)
  end

  it 'allows one kept prediction per pool, user and match' do
    prediction = create(:bolao_prediction)
    duplicate = build(:bolao_prediction, pool: prediction.pool, user: prediction.user, match: prediction.match)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)

    prediction.discard
    expect(duplicate.save).to be(true)
  end
end
