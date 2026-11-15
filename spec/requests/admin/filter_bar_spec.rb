require 'rails_helper'

RSpec.describe 'Admin FilterBar', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'shows saved views, chips when filtering, and clear-all' do
    create(:match, status: 'live', match_date: 1.hour.ago)

    get '/admin/matches', params: { q: { status_eq: 'live' }, scope: 'all' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-role="filter-bar"', 'data-role="filter-saved-views"')
    expect(response.body).to include('Minhas Pendências', 'Rodada Atual', 'Todas as Partidas')
    expect(response.body).to include('data-role="filter-chip"', 'Situação:')
    expect(response.body).to include('data-role="filter-clear-all"', 'Limpar todos')
  end

  it 'toggles Lista and Por rodada in the collection toolbar' do
    create(:match)

    get '/admin/matches', params: { scope: 'all', view: 'table' }

    expect(response.body).to include('data-role="view-toggle"', 'Lista', 'Por rodada')
  end

  it 'shows empty state with Limpar Filtros when nothing matches' do
    get '/admin/matches', params: { q: { status_eq: 'live' }, scope: 'all' }

    expect(response.body).to include('data-role="empty-state"', 'Limpar Filtros', 'data-role="clear-filters"')
  end
end
