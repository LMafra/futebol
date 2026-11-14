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

  it 'shows four status-first KPIs with no quick-action grid, and Criar campeonato as a header CTA' do
    sign_in(create(:user, :admin))
    get '/admin'

    expect(response.body).to include('data-role="admin-metrics"', 'lg:grid-cols-4')
    expect(response.body).to include('Campeonatos ativos', 'Partidas ao vivo')
    expect(response.body).to include('Pontuação pendente', 'Gestores pendentes')
    expect(response.body).not_to include('admin-quick-actions', 'Ações rápidas')
    header_cta = Nokogiri::HTML(response.body).at_css('[data-test-page-header] a[data-role="header-cta"]')
    expect([header_cta.text, header_cta['href']]).to eq(['Criar campeonato', '/admin/championships/new'])
    expect(header_cta['class'].split).to include('bg-white')
    expect(header_cta['class'].split).not_to include('bg-cartola')
    expect(response.body).to include('font-numeric', 'text-3xl', 'border-l-[3px]')
    expect(response.body).to include('data-role="admin-kpi"', '<svg')
    expect(response.body).to include('data-role="admin-recent-matches"', 'Últimas partidas')
  end
end
