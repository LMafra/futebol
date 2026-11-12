require 'rails_helper'

RSpec.describe 'Admin manager approval feedback', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:pending_manager) { create(:user, :pending_manager) }

  before { sign_in(admin) }

  it 'updates the manager status badge via turbo stream without a full redirect' do
    put approve_manager_admin_user_path(pending_manager),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include('turbo-stream', 'manager-status-badge', 'aprovado')
    expect(response.body).to include('Gestor aprovado.', 'data-role="admin-toast"')
    expect(pending_manager.reload.manager_status).to eq('approved')
  end
end
