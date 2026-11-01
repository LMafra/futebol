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

  describe 'betting window' do
    let(:match) { create(:match) }

    it 'accepts a bet while the match is scheduled' do
      expect(build(:bolao_prediction, match:)).to be_valid
    end

    it 'rejects a new bet once the match is not scheduled' do
      %w[live finished scored reverted].each do |status|
        match.status = status
        prediction = build(:bolao_prediction, match:)

        expect(prediction).not_to be_valid, status
        expect(prediction.errors[:base]).to include('Palpites encerrados para esta partida.')
      end
    end

    it 'rejects changing the guess after kickoff but still allows touching other columns' do
      prediction = create(:bolao_prediction, match:)
      match.update_columns(status: 'live')

      expect(prediction.reload.update(home_guess: 4)).to be(false)
      expect(prediction.reload.discard).to be(true)
    end

    it 'skips the window for the :backfill context (past predictions)' do
      match.update_columns(status: 'finished', home_score: 1, away_score: 0)

      expect(build(:bolao_prediction, match:).save(context: :backfill)).to be(true)
    end
  end

  it 'rejects a second kept prediction for the same pool, user and match' do
    prediction = create(:bolao_prediction)
    duplicate = build(:bolao_prediction, pool: prediction.pool, user: prediction.user, match: prediction.match)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:match_id]).to be_present
  end

  it 'allows one kept prediction per pool, user and match' do
    prediction = create(:bolao_prediction)
    duplicate = build(:bolao_prediction, pool: prediction.pool, user: prediction.user, match: prediction.match)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)

    prediction.discard
    expect(duplicate.save).to be(true)
  end
end
