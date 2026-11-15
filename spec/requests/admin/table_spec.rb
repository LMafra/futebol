require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar tables', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'styles the players table with a pitch thead, numeric columns and SVG actions' do
    create(:player)

    get '/admin/players'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-role="collection-table"')
    expect(response.body).to match(/<thead[^>]*class="[^"]*bg-pitch/)
    expect(response.body).to include('tabular-nums', 'data-role="admin-table-action"', 'title=')
    expect(response.body).to include('Jogadores', 'Jogador', 'Posição')
    expect(response.body).not_to include('Players')
    sheet = File.read(Rails.root.join('app/assets/stylesheets/active_admin.css'))
    expect(sheet).to include('nth-child(odd)', 'nth-child(even)', 'bg-paper', 'bg-white', 'tabular-nums')
  end

  it 'renders the filter bar above the index table' do
    create(:championship)

    get '/admin/championships'

    expect(response.body).to include('data-role="admin-filter-bar"', 'filters-form', 'data-role="filter-bar"')
    filter_at = response.body.index('data-role="admin-filter-bar"')
    table_at = response.body.index('data-role="collection-cards"')
    expect(filter_at).to be < table_at
    sheet = File.read(Rails.root.join('app/assets/stylesheets/active_admin.css'))
    expect(sheet).not_to match(/#filters_sidebar_section/)
    expect(sheet).not_to match(/\[data-role="admin-filter-bar"\]/)
    %w[.page-title [data-test-page-header] data-status=sim data-status=não].each do |dead|
      expect(sheet).not_to include(dead)
    end
  end

  it 'paginates with pitch current page instead of Flowbite blue' do
    create_list(:match, 35)

    get '/admin/matches', params: { scope: 'all' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-test-pagination', 'bg-pitch')
    expect(response.body).not_to include('bg-blue-500')
  end
end
