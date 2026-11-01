require 'rails_helper'

RSpec.describe Ui::PredictionFormComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::PredictionFormComponentPreview

  let(:pool) { create(:bolao_pool) }
  let(:match) { create(:match, championship: pool.championship) }

  it 'requires match and prediction in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /match is required/)
  end

  it 'posts a new bet with the match id' do
    page = render_inline(described_class.new(match:, prediction: Bolao::Prediction.new(pool:, match:)))

    expect(page.at_css("form[action='/pools/#{pool.id}/bets']")).to be_present
    expect(page.at_css('input[name="prediction[match_id]"]')['value']).to eq(match.id.to_s)
    expect(page.at_css('input[type="submit"]')['value']).to eq('Palpitar')
  end

  it 'patches an existing bet' do
    prediction = create(:bolao_prediction, pool:, match:)
    page = render_inline(described_class.new(match:, prediction:))

    expect(page.at_css("form[action='/pools/#{pool.id}/bets/#{prediction.id}']")).to be_present
    expect(page.at_css('input[name="prediction[match_id]"]')).to be_nil
  end

  it 'shows the saved guess when bets are closed' do
    prediction = create(:bolao_prediction, pool:, match:, home_guess: 2, away_guess: 1)
    page = render_inline(described_class.new(match:, prediction:, state: :empty))

    expect(page.at_css('[data-role="closed"]').text.squish).to eq('Palpites encerrados · seu palpite 2 × 1')
    expect(page.at_css('form')).to be_nil
  end

  it 'shows base and field errors' do
    prediction = Bolao::Prediction.new(pool:, match:, home_guess: -1, away_guess: 0)
    prediction.errors.add(:base, 'Palpites encerrados para esta partida.')
    prediction.errors.add(:home_guess, 'deve ser maior ou igual a 0')
    page = render_inline(described_class.new(match:, prediction:, state: :error))

    expect(page.at_css('[data-role="errors"]').text).to include('Palpites encerrados para esta partida.')
    expect(page.at_css('[data-role="field-error"]').text).to eq('deve ser maior ou igual a 0')
  end
end
