require 'rails_helper'

RSpec.describe 'Esquadrão rankings', type: :request do
  let!(:championship) { create(:championship) }

  it 'redireciona para o login sem sessão' do
    get esquadrao_rankings_path

    expect(response).to redirect_to(new_session_path)
  end

  it 'redireciona /cartola/rankings para /esquadrao/rankings (301) mantendo a query string' do
    get '/cartola/rankings?tab=coins&championship_id=7'

    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('/esquadrao/rankings?tab=coins&championship_id=7')
  end

  context 'with a session' do
    before { sign_in(create(:user, name: 'Visitante')) }

    it 'mostra o ranking de pontos por padrão, com os pontos do capitão em dobro' do
      player = create(:player, position: 'ATA')
      create(:cartola_player_score, player:, match: create(:match, championship:, round: 1), points: 9)
      create(:cartola_lineup, squad: create(:cartola_squad, user: create(:user, name: 'Ana')), championship:,
                              players: [player])

      get esquadrao_rankings_path

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('p.uppercase').text).to start_with('Esquadrão')
      expect(page.at_css('thead').text).to include('Técnico')
      expect(page.at_css('nav[aria-label="Rankings"] a[aria-current="page"]').text).to eq('Pontos')
      expect(page.css('[data-role="ranking-row"]').map { |row| row.text.squish }).to eq(['1 Ana 18.00'])
    end

    it 'mostra o ranking de moedas na outra aba' do
      create(:cartola_wallet, championship:, balance: 70, user: create(:user, name: 'Bia'))

      get esquadrao_rankings_path(tab: 'coins', championship_id: championship.id)

      page = Nokogiri::HTML(response.body)
      expect(page.at_css('nav[aria-label="Rankings"] a[aria-current="page"]').text).to eq('Moedas')
      expect(page.css('[data-role="ranking-row"]').map { |row| row.text.squish }).to eq(['1 Bia C$ 70.00'])
    end

    it 'responde 404 para campeonato inexistente' do
      get esquadrao_rankings_path(championship_id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
