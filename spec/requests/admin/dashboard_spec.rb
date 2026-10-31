require 'rails_helper'

RSpec.describe 'ActiveAdmin dashboard', type: :request do
  it 'requires a session' do
    get '/admin'

    expect(response).to redirect_to(new_session_path)
  end

  it 'rejects signed-in users who are not admins' do
    sign_in(create(:user))
    get '/admin'

    expect(response).to redirect_to(root_path)
  end

  it 'renders on Rails 8.1 with the Tailwind-built admin stylesheet for admins' do
    sign_in(create(:user, :admin))
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Dashboard')
    expect(response.body).to match(%r{/assets/active_admin-\h+\.css})
  end
end
