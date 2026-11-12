require 'rails_helper'

RSpec.describe 'Authentication by area', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:user) { create(:user) }

  it 'admin vai para /admin após entrar' do
    post session_path, params: { email_address: admin.email_address, password: 'password123' }

    expect(response).to redirect_to(admin_root_url)
  end

  it 'gestor vai para /gestor após entrar' do
    post session_path, params: { email_address: manager.email_address, password: 'password123' }

    expect(response).to redirect_to(gestor_root_url)
  end

  it 'torcedor vai para a home após entrar' do
    post session_path, params: { email_address: user.email_address, password: 'password123' }

    expect(response).to redirect_to(root_url)
  end

  it 'torcedor é recusado em /gestor/login' do
    post session_path, params: { email_address: user.email_address, password: 'password123', area: 'gestor' }

    expect(response).to redirect_to(gestor_login_path)
    expect(flash[:alert]).to include('não tem acesso')
    expect(user.sessions).to be_empty
  end

  it 'gestor é recusado em /admin/login' do
    post session_path, params: { email_address: manager.email_address, password: 'password123', area: 'admin' }

    expect(response).to redirect_to(admin_login_path)
    expect(flash[:alert]).to include('não tem acesso')
    expect(manager.sessions).to be_empty
  end

  it 'páginas de login das áreas enviam o campo area oculto' do
    get admin_login_path
    admin_page = Nokogiri::HTML(response.body)
    expect(admin_page.at_css('input[name="area"][type="hidden"]')['value']).to eq('admin')

    get gestor_login_path
    gestor_page = Nokogiri::HTML(response.body)
    expect(gestor_page.at_css('input[name="area"][type="hidden"]')['value']).to eq('gestor')
  end
end
