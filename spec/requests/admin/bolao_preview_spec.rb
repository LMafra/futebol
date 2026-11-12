require 'rails_helper'

RSpec.describe 'Admin BolaoPreview page', type: :request do
  let(:match) { create(:match, status: 'live', home_score: 0, away_score: 0, match_date: 1.hour.ago) }
  let(:pool) { create(:bolao_pool, name: 'Bolão da Firma') }
  let!(:exact) { create(:bolao_prediction, pool:, match:, home_guess: 2, away_guess: 1) }
  let!(:miss) { create(:bolao_prediction, pool:, match:, home_guess: 0, away_guess: 3) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
    sign_in(create(:user, :admin))
  end

  it 'mostra o formulário de candidate_home/candidate_away antes de calcular' do
    get '/admin/bolaopreview', params: { match_id: match.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="candidate_home"', 'name="candidate_away"')
    expect(response.body).not_to include('data-role="preview"')
  end

  it 'preview Bolão renderiza com candidate scores (sem usar o placar real nem gravar nada)' do
    expect do
      get '/admin/bolaopreview', params: { match_id: match.id, candidate_home: 2, candidate_away: 1 }
    end.not_to change(Bolao::PredictionScore, :count)

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('[data-role="candidate-score"]').text.squish).to eq('2 × 1')
    expect(page.css('[data-role="points"]').map(&:text)).to eq(%w[10 0])
    expect(page.at_css('[data-role="total"]').text).to eq('10')
    expect(page.text).to include('Bolão da Firma')
    expect(page.at_css('[data-role="confirm-score"]')['href']).to eq("/admin/matchfinalizer?match_id=#{match.id}")
  end

  it 'candidato inválido → mensagem de erro, sem preview' do
    get '/admin/bolaopreview', params: { match_id: match.id, candidate_home: -1, candidate_away: 1 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Informe os dois placares candidatos')
    expect(response.body).not_to include('data-role="preview"')
  end

  it 'não-admin recebe 403' do
    sign_in(create(:user))

    get '/admin/bolaopreview', params: { match_id: match.id, candidate_home: 2, candidate_away: 1 }

    expect(response).to have_http_status(:forbidden)
  end
end
