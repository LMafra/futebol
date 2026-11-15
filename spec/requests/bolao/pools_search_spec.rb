require 'rails_helper'

RSpec.describe 'Bolão pools search', type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user, name: 'Membro Busca') }
  let(:championship) { create(:championship, name: 'Copa Busca') }
  let!(:alpha) { create(:bolao_pool, owner:, championship:, name: 'Bolão Alpha') }
  let!(:beta) { create(:bolao_pool, owner:, championship:, name: 'Bolão Beta') }

  before do
    alpha.memberships.create!(user: member)
    beta.memberships.create!(user: member)
    sign_in(member)
  end

  it 'filtra os bolões do usuário pelo nome' do
    get pools_path, params: { q: 'Alpha' }

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    names = page.css('[data-role="pools"] [data-role="pool-card"]').map { |node| node.at_css('a').text }
    expect(names).to eq(['Bolão Alpha'])
    expect(page.at_css('[data-role="pools-search-input"]')['value']).to eq('Alpha')
  end

  it 'mostra empty state com CTA quando a busca não encontra bolão' do
    get pools_path, params: { q: 'Inexistente' }

    expect(response).to have_http_status(:ok)
    empty = Nokogiri::HTML(response.body).at_css('[data-role="pools-empty"] [data-role="empty-state"]')
    expect(empty.text).to include('Nenhum bolão encontrado', 'Tente outro nome ou peça o código')
  end

  it 'mostra empty state pedindo código quando o usuário não participa de nenhum bolão' do
    stranger = create(:user)
    sign_in(stranger)

    get pools_path

    empty = Nokogiri::HTML(response.body).at_css('[data-role="pools-empty"] [data-role="empty-state"]')
    expect(empty.text).to include('Você ainda não está em nenhum bolão', 'Peça o código ao organizador')
    expect(empty.text).not_to include('bolão público')
  end

  it 'mostra posição e membros no card; código só para o dono' do
    get pools_path
    page = Nokogiri::HTML(response.body)
    card = page.at_css(%([data-role="pool-card"][data-pool-id="#{alpha.id}"]))
    expect(card.text).to include('Copa Busca', 'membros', 'Posição')
    expect(card.at_css('[data-role="pool-code"]')).to be_nil

    sign_in(owner)
    alpha.memberships.find_or_create_by!(user: owner)
    get pools_path
    owner_card = Nokogiri::HTML(response.body).at_css(%([data-role="pool-card"][data-pool-id="#{alpha.id}"]))
    expect(owner_card.at_css('[data-role="pool-code"]')).to be_present
    expect(owner_card.at_css('[data-clipboard-target="source"]').text).to eq(alpha.code)
  end
end
