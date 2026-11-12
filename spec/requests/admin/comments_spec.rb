require 'rails_helper'

RSpec.describe 'Admin comments', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship) }

  it 'admin cria comentário em um campeonato' do
    sign_in(admin)

    expect do
      post '/admin/comments', params: {
        comment: {
          body: 'Observação sobre o campeonato',
          resource_type: 'Core::Championship',
          resource_id: championship.id
        }
      }
    end.to change(ActiveAdmin::Comment, :count).by(1)

    comment = ActiveAdmin::Comment.last
    expect(comment).to have_attributes(body: 'Observação sobre o campeonato', namespace: 'admin',
                                       author: admin, resource: championship)

    get "/admin/comments/#{comment.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Observação sobre o campeonato')
  end

  it 'gestor recebe 403 em /admin/comments' do
    sign_in(manager)

    get '/admin/comments'

    expect(response).to have_http_status(:forbidden)
  end

  it '/gestor/comments responde 404' do
    sign_in(manager)

    get '/gestor/comments'

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq('Not Found')
  end
end
