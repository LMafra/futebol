require 'rails_helper'

RSpec.describe 'Gestor dashboard', type: :request do
  it 'shows championship cards first, then KPI strip and upcoming matches' do
    manager = create(:user, :manager)
    create(:championship, manager:, name: 'Copa do Gestor')
    sign_in(manager)

    get '/gestor'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Copa do Gestor', 'data-role="gestor-championships"')
    expect(response.body).to include('data-role="gestor-kpis"', 'Times cadastrados', 'Jogadores', 'Partidas pendentes')
    expect(response.body).to include('lg:col-span-8', 'lg:col-span-4')
    expect(response.body).to include('data-role="gestor-upcoming-matches"', 'Próximas partidas')
  end
end
