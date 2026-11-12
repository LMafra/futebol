require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar tables', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'styles championship index thead with pitch' do
    create(:championship)

    get '/admin/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-table')
    expect(response.body).to match(/<thead[^>]*class="[^"]*bg-pitch/)
  end
end
