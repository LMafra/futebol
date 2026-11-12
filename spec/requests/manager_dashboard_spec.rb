require 'rails_helper'

RSpec.describe 'Gestor dashboard', type: :request do
  let(:manager) { create(:user, :manager) }

  def page_html = Nokogiri::HTML(response.body)

  it 'lista campeonatos do gestor com contadores' do
    championship = create(:championship, manager:, name: 'Copa Teste')
    home = create(:team)
    away = create(:team)
    create(:player, team: home)
    create(:match, championship:, home_team: home, away_team: away, status: 'scheduled')
    create(:bolao_pool, championship:)

    sign_in(manager)
    get '/gestor/dashboard'

    expect(response).to have_http_status(:ok)
    card = page_html.at_css("[data-championship-id='#{championship.id}']")
    expect(card).to be_present
    expect(card.at_css('[data-counter="teams"]').text.to_i).to eq(2)
    expect(card.at_css('[data-counter="players"]').text.to_i).to eq(1)
    expect(card.at_css('[data-counter="matches"]').text).to include('1')
    expect(card.at_css('[data-counter="pools"]').text.to_i).to eq(1)
  end

  it 'leva Scouts, Finalizar e Reverter para a fila de partidas, não para atalhos globais' do
    sign_in(manager)
    get '/gestor/dashboard'

    shortcuts = page_html.at_css('[data-role="gestor-shortcuts"]')
    expect(shortcuts.text).not_to include('Scouts', 'Finalizar', 'Reverter')
  end

  it 'mostra estado vazio sem campeonatos' do
    sign_in(manager)
    get '/gestor/dashboard'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Você ainda não tem campeonatos', 'data-role="empty-state"')
    expect(page_html.at_css('[data-role="gestor-championships"]')).to be_nil
  end

  it 'salva premiação pelo formulário do campeonato' do
    championship = create(:championship, manager:)
    sign_in(manager)

    patch "/gestor/championships/#{championship.id}", params: {
      championship: {
        name: championship.name,
        season: championship.season,
        private: false,
        prize_description: 'Troféu e medalhas',
        first_place: 'R$ 500'
      }
    }

    expect(response).to redirect_to(gestor_championship_path(championship))
    expect(championship.reload).to have_attributes(prize_description: 'Troféu e medalhas', first_place: 'R$ 500')
  end
end
