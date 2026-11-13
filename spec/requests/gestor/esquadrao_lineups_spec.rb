require 'rails_helper'

RSpec.describe 'Gestor › Escalações do Esquadrão', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, name: 'Copa do Gestor') }
  let!(:lineup) { create(:cartola_lineup, championship:, round: 3) }

  before { sign_in(manager) }

  it 'lista as escalações com os filtros de campeonato e rodada' do
    get '/gestor/esquadrao_lineups'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lineup.squad.name)
  end

  it 'filtra por campeonato e rodada' do
    get '/gestor/esquadrao_lineups', params: { q: { championship_id_eq: championship.id, round_eq: 3 } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lineup.squad.name)
  end
end
