require 'rails_helper'

RSpec.describe 'Cartola rankings', type: :request do
  let!(:championship) { create(:championship) }

  it 'redireciona para o login sem sessão' do
    get cartola_rankings_path

    expect(response).to redirect_to(new_session_path)
  end

  context 'with a session' do
    before { sign_in(create(:user, name: 'Visitante')) }

    it 'mostra o ranking de pontos por padrão' do
      player = create(:player, position: 'ATA')
      create(:cartola_player_score, player:, match: create(:match, championship:, round: 1), points: 9)
      create(:cartola_lineup, squad: create(:cartola_squad, user: create(:user, name: 'Ana')), championship:,
                              players: [player])

      get cartola_rankings_path

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('[role="tab"][aria-selected="true"]').text).to eq('Pontos')
      expect(page.css('[data-role="ranking-row"]').map { |row| row.text.squish }).to eq(['1 Ana 9.00'])
    end

    it 'mostra o ranking de cartoletas na outra aba' do
      create(:cartola_wallet, championship:, balance: 70, user: create(:user, name: 'Bia'))

      get cartola_rankings_path(tab: 'coins', championship_id: championship.id)

      page = Nokogiri::HTML(response.body)
      expect(page.at_css('[role="tab"][aria-selected="true"]').text).to eq('Cartoletas')
      expect(page.css('[data-role="ranking-row"]').map { |row| row.text.squish }).to eq(['1 Bia C$ 70.00'])
    end

    it 'responde 404 para campeonato inexistente' do
      get cartola_rankings_path(championship_id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
