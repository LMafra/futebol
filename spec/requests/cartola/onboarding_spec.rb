require 'rails_helper'

RSpec.describe 'Esquadrão onboarding', type: :request do
  let(:user) { create(:user) }
  let!(:championship) { create(:championship, name: 'Liga Onboarding') }

  before { sign_in(user) }

  it 'mostra o tour de 3 passos na primeira visita sem lineup' do
    get esquadrao_path, params: { championship_id: championship.id }

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    tour = page.at_css('[data-role="esquadrao-tour"]')
    expect(tour).to be_present
    expect(tour.css('[data-role="tour-step"]').size).to eq(3)
    expect(page.at_css('[data-role="budget-spent"], [data-role="budget-progress"]')).to be_present
  end

  it 'pula o tour e não mostra de novo na sessão' do
    get esquadrao_path, params: { championship_id: championship.id, pular_tour: 1 }
    expect(response).to redirect_to(lineup_path(championship_id: championship.id))

    follow_redirect!
    expect(Nokogiri::HTML(response.body).at_css('[data-role="esquadrao-tour"]')).to be_nil
  end

  it 'mostra badge de posição e feedback inline ao salvar escalação inválida' do
    team = create(:team)
    championship.championship_teams.find_or_create_by!(team:)
    create(:player, team:, position: 'MEI', name: 'Meia Solo')
    create(:cartola_wallet, user:, championship:, balance: 100)

    get edit_lineup_path(championship_id: championship.id)
    expect(response.body).to include('data-role="position-badge"')

    patch lineup_path(championship_id: championship.id),
          params: { lineup: { formation: '4-3-3', player_ids: [], captain_id: '' } }

    expect(response).to have_http_status(:unprocessable_content)
    errors = Nokogiri::HTML(response.body).at_css('[data-role="lineup-inline-errors"]')
    expect(errors).to be_present
    expect(errors.text).to match(/jogador|capitão|escalação/i)
  end
end
