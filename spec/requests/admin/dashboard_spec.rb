require 'rails_helper'

RSpec.describe 'ActiveAdmin dashboard', type: :request do
  it 'renders on Rails 8.1 with the Tailwind-built admin stylesheet' do
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Dashboard')
    expect(response.body).to match(%r{/assets/active_admin-\h+\.css})
  end
end
