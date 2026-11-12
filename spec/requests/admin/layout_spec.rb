require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar layout chrome', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'renders pitch header, paper nav, and GitHub footer' do
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Craquefy', 'font-display', 'bg-pitch', 'text-paper')
    expect(response.body).to include('data-role="craquefy-admin-header"')
    expect(response.body).to include('data-role="craquefy-admin-nav"', 'bg-paper', 'border-rule')
    expect(response.body).to include('data-role="craquefy-admin-footer"')
    expect(response.body).to include('https://github.com/LMafra/futebol')
    expect(response.body).to include('fonts.googleapis.com')
  end
end
