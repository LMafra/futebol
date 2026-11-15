require 'rails_helper'

RSpec.describe 'Gestor namespace', type: :request do
  let(:manager) { create(:user, :manager) }
  let!(:own_championship) { create(:championship, manager:, name: 'Meu Campeonato') }
  let!(:foreign_championship) { create(:championship, name: 'Campeonato Alheio') }

  it 'visitante sem sessão é enviado ao login' do
    get '/gestor'

    expect(response).to redirect_to(new_session_path)
  end

  it 'usuário comum recebe 403 em /gestor' do
    sign_in(create(:user))

    get '/gestor'

    expect(response).to have_http_status(:forbidden)
  end

  it 'gestor pendente recebe 403 em /gestor' do
    sign_in(create(:user, :pending_manager))

    get '/gestor'

    expect(response).to have_http_status(:forbidden)
  end

  it 'gestor aprovado acessa /gestor' do
    sign_in(manager)

    get '/gestor'

    expect(response).to have_http_status(:ok)
  end

  it 'admin acessa /gestor' do
    sign_in(create(:user, :admin))

    get '/gestor'

    expect(response).to have_http_status(:ok)
  end

  it 'gestor recebe 403 em /admin' do
    sign_in(manager)

    get '/admin'

    expect(response).to have_http_status(:forbidden)
  end

  it 'lista só os campeonatos do gestor' do
    sign_in(manager)

    get '/gestor/championships'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Meu Campeonato')
    expect(response.body).not_to include('Campeonato Alheio')
  end

  it 'cria campeonato atribuído ao gestor' do
    sign_in(manager)

    expect do
      post '/gestor/championships', params: {
        championship: {
          name: 'Copa Nova', season: 2026, private: false,
          cartola_goalkeeper_limit: 1, cartola_defender_limit: 2,
          cartola_midfielder_limit: 3, cartola_forward_limit: 3
        }
      }
    end.to change(Core::Championship, :count).by(1)

    championship = Core::Championship.order(:id).last
    expect(championship).to have_attributes(name: 'Copa Nova', manager:, status: 'draft')
    expect(response).to redirect_to(edit_gestor_championship_path(championship, step: 'modalidade'))
  end

  it 'comentários do ActiveAdmin não existem em /gestor' do
    sign_in(manager)

    get '/gestor/comments'

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq('Not Found')
  end
end
