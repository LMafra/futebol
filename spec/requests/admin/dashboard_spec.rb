require 'rails_helper'

RSpec.describe 'ActiveAdmin dashboard', type: :request do
  it 'requires a session' do
    get '/admin'

    expect(response).to redirect_to(new_session_path)
  end

  it 'answers 403 (Pundit via ActiveAdmin::PunditAdapter) to signed-in users who are not admins' do
    sign_in(create(:user))
    get '/admin'

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include('Acesso negado')
  end

  it 'renders on Rails 8.1 with the Tailwind-built admin stylesheet for admins' do
    sign_in(create(:user, :admin))
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Painel Administrativo', 'lang="pt-BR"')
    expect(response.body).to match(%r{/assets/active_admin-\h+\.css})
  end

  it 'shows metric cards including Campeonatos on an 8/4 grid' do
    sign_in(create(:user, :admin))
    get '/admin'

    expect(response.body).to include('data-role="admin-metrics"', 'Campeonatos', 'lg:col-span-8', 'lg:col-span-4')
    expect(response.body).to include('font-numeric', 'text-3xl')
  end
end
