require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar tables', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'styles championship index thead with pitch, zebra, and SVG actions' do
    create(:championship)

    get '/admin/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-table')
    expect(response.body).to match(/<thead[^>]*class="[^"]*bg-pitch/)
    expect(response.body).to include('data-table', 'tabular-nums')
    expect(response.body).to include('data-role="admin-table-actions"', 'data-role="admin-table-action"', 'title=')
    expect(response.body).to include('Campeonatos', 'Nome', 'Temporada')
    expect(response.body).not_to include('Championships')
    sheet = File.read(Rails.root.join('app/assets/stylesheets/active_admin.css'))
    expect(sheet).to include('nth-child(odd)', 'nth-child(even)', 'bg-paper', 'bg-white', 'tabular-nums')
  end

  it 'renders the filter bar above the index table' do
    create(:championship)

    get '/admin/championships'

    expect(response.body).to include('data-role="admin-filter-bar"', 'filters-form')
    filter_at = response.body.index('data-role="admin-filter-bar"')
    table_at = response.body.index('data-table')
    expect(filter_at).to be < table_at
  end

  it 'paginates with pitch current page instead of Flowbite blue' do
    create_list(:match, 35)

    get '/admin/matches'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-test-pagination', 'bg-pitch')
    expect(response.body).not_to include('bg-blue-500')
  end
end
