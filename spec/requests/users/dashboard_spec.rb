require 'rails_helper'

RSpec.describe 'Users::Dashboard (/minha-area)', type: :request do
  let(:user) { create(:user, name: 'Ana Torcedora') }
  let(:championship) { create(:championship, name: 'Liga Teste', season: 2026) }
  let(:pool) { create(:bolao_pool, championship:, owner: user, name: 'Bolão Amigos') }

  before do
    pool.memberships.find_or_create_by!(user:)
  end

  it 'exige login' do
    get users_dashboard_path

    expect(response).to redirect_to(new_session_path)
  end

  context 'with a session' do
    let!(:open_match) do
      create(:match, championship:, match_date: 5.hours.from_now, status: 'scheduled', round: 1)
    end

    before { sign_in(user) }

    it 'responde 200 com KPIs, pendências, bolões e simulador' do
      get users_dashboard_path

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('[data-role="users-dashboard"] h1').text).to include('Olá, Ana Torcedora!')
      labels = page.css('[data-role="dashboard-kpis"] [data-role="kpi-card"]').map { |node| node['data-label'] }
      expect(labels).to eq(['Palpites em aberto', 'Escalação da rodada', 'Classificação'])
      expect(page.at_css('[data-role="dashboard-pendencias"] [data-role="action-center"]')).to be_present
      expect(page.at_css('[data-role="dashboard-pendencias"]').text).to include(open_match.home_team.name)
      expect(page.at_css('[data-role="pool-card"]').text).to include('Bolão Amigos', championship.name)
      expect(page.at_css('[data-role="simulator-link"]')['href']).to eq(simulador_championship_path(championship))
    end

    it 'lista pendência de escalação quando não há lineup' do
      get users_dashboard_path

      expect(response.body).to include('Escalação da rodada', 'Montar escalação')
    end
  end

  it 'redireciona o torcedor para /minha-area após o login' do
    post session_path, params: { email_address: user.email_address, password: 'password123' }

    expect(response).to redirect_to(users_dashboard_url)
  end
end
