require 'rails_helper'

RSpec.describe 'ActiveAdmin task navigation', type: :request do
  def menu_tree
    nav = Nokogiri::HTML(response.body).at_css('[data-role="craquefy-admin-task-nav"]')
    nav.css('> li').to_h { |li| [li['data-nav-section'], li.css('ul li a').map { |a| a.text.strip }] }
  end

  describe 'admin' do
    before { sign_in(create(:user, :admin)) }

    it 'groups screens by Campeonatos, Times, Participantes and Configurações' do
      get '/admin'

      expect(response).to have_http_status(:ok)
      expect(menu_tree).to eq(
        'Painel Administrativo' => [],
        'Campeonatos' => %w[Campeonatos Partidas],
        'Times' => %w[Times Jogadores],
        'Participantes' => ['Bolões', 'Esquadrão', 'Times do Esquadrão', 'Usuários'],
        'Configurações' => ['Regras do Bolão', 'Regras do Esquadrão', 'Testar regras', 'Importações CSV',
                            'Histórico de auditoria', 'Comentários']
      )
      expect(response.body).to include('stroke="currentColor"')
    end
  end

  describe 'gestor' do
    before { sign_in(create(:user, :manager)) }

    it 'shows the same tree without the admin-only screens' do
      get '/gestor'

      expect(response).to have_http_status(:ok)
      expect(menu_tree).to eq(
        'Painel' => [],
        'Campeonatos' => %w[Campeonatos Partidas],
        'Times' => %w[Times Jogadores],
        'Participantes' => %w[Bolões Esquadrão],
        'Configurações' => ['Regras do Bolão']
      )
      expect(response.body).not_to include('Histórico de auditoria', '>Usuários<')
    end
  end
end
