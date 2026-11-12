require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar tables', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'styles championship index thead with pitch' do
    create(:championship)

    get '/admin/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-table')
    expect(response.body).to match(/<thead[^>]*class="[^"]*bg-pitch/)
    expect(response.body).to include('Campeonatos', 'Nome', 'Temporada')
    expect(response.body).not_to include('Championships')
  end

  it 'paginates with pitch current page instead of Flowbite blue' do
    create_list(:match, 35)

    get '/admin/matches'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-test-pagination', 'bg-pitch')
    expect(response.body).not_to include('bg-blue-500')
  end
end
