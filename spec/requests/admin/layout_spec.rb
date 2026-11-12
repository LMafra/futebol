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

  it 'renders the resource page header with paper and rule instead of gray-50' do
    create(:championship)

    get '/admin/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-test-page-header')
    expect(response.body).to include('bg-paper', 'border-rule', 'font-display')
    expect(response.body).not_to include('bg-gray-50 border-b border-gray-200')
  end

  it 'renders a Placar blank slate when the index has no records' do
    get '/admin/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-role="craquefy-admin-blank-slate"', 'border-rule', 'bg-paper')
    expect(response.body).not_to include('border-gray-300')
  end

  it 'styles championship show attributes with paper th instead of gray-50' do
    championship = create(:championship)

    get "/admin/championships/#{championship.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('attributes-table')
    expect(response.body).to include('Campeonato')
  end
end
