require 'rails_helper'

RSpec.describe 'Contextual empty states', type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  it 'mostra empty state na área pessoal sem bolões' do
    get users_dashboard_path

    empty = Nokogiri::HTML(response.body).at_css('[data-role="dashboard-pools"] [data-role="empty-state"]')
    expect(empty.text).to include('Você ainda não está em nenhum bolão', 'Peça o código ao organizador')
  end

  it 'mostra empty state no Esquadrão sem lineup' do
    create(:championship)
    get esquadrao_path

    empty = Nokogiri::HTML(response.body).at_css('[data-role="lineup-empty"] [data-role="empty-state"]')
    expect(empty.text).to include('Monte sua primeira escalação', 'Escolha a formação e compre jogadores')
  end

  it 'mostra empty state na busca de bolões sem resultados' do
    get pools_path, params: { q: 'NaoExisteXYZ' }

    empty = Nokogiri::HTML(response.body).at_css('[data-role="pools-empty"] [data-role="empty-state"]')
    expect(empty.text).to include('Nenhum bolão encontrado', 'Tente outro nome ou peça o código')
  end
end
