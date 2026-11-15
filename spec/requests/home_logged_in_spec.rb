require 'rails_helper'

RSpec.describe 'Home logged in', type: :request do
  let(:user) { create(:user) }
  let(:championship) { create(:championship, name: 'Liga Participo', private: false, status: 'published') }
  let(:pool) { create(:bolao_pool, championship:, owner: user, name: 'Meu Bolão') }

  before do
    pool.memberships.find_or_create_by!(user:)
    sign_in(user)
  end

  it 'mostra banner Ir para Minha área e badge Você participa' do
    get root_path

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('[data-role="logged-in-home-banner"]')).to be_present
    expect(page.at_css('[data-role="goto-minha-area"]')['href']).to eq(users_dashboard_path)
    card = page.at_css(%([data-role="championship-card"][data-championship-id="#{championship.id}"]))
    expect(card.at_css('[data-role="you-participate"]').text).to eq('Você participa')
    expect(card.at_css('[data-role="simulate-championship"]').text).to include('Simular este campeonato')
  end

  it 'mantém Minha área no menu da conta' do
    get root_path

    menu = Nokogiri::HTML(response.body).at_css('header [data-role="account-menu"]')
    expect(menu.css('a').map(&:text)).to include('Minha área', 'Meus bolões', 'Meu esquadrão',
                                                 'Classificação do Esquadrão')
  end
end
