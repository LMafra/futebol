require 'rails_helper'

RSpec.describe 'ActiveAdmin task navigation', type: :request do
  describe 'admin' do
    before { sign_in(create(:user, :admin)) }

    it 'shows task sections including Participantes and Auditoria' do
      get '/admin'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-role="craquefy-admin-task-nav"')
      expect(response.body).to include('Meus campeonatos', 'Partidas', 'Participantes', 'Configurações', 'Auditoria')
      expect(response.body).to include('Usuários', 'Histórico')
      expect(response.body).to include('stroke="currentColor"')
    end
  end

  describe 'gestor' do
    before { sign_in(create(:user, :manager)) }

    it 'hides admin-only Auditoria and Usuários sections' do
      get '/gestor'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Meus campeonatos', 'Partidas', 'Participantes', 'Configurações')
      expect(response.body).not_to include('>Auditoria<')
      expect(response.body).not_to include('>Usuários<')
      expect(response.body).not_to include('Histórico de auditoria')
    end
  end
end
