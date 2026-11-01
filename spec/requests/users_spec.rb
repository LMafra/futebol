require 'rails_helper'

RSpec.describe 'Users (public signup)', type: :request do
  def signup(**overrides)
    attributes = { name: 'Torcedor Novo', email_address: 'novo@futebol.test',
                   password: 'senha-forte', password_confirmation: 'senha-forte' }
    post users_path, params: { user: attributes.merge(overrides) }
  end

  it 'creates an active user and starts a session' do
    expect { signup }.to change(Core::User, :count).by(1).and change(Core::Session, :count).by(1)

    user = Core::User.find_by!(email_address: 'novo@futebol.test')
    expect(user).to be_active
    expect(user.sessions.last.ip_address).to be_present
  end

  it 'redirects to root with the "Conta criada" notice, already signed in' do
    signup

    expect(response).to redirect_to(root_path)
    expect(flash[:notice]).to eq('Conta criada')
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it 'answers 422 for a duplicated email' do
    create(:user, email_address: 'novo@futebol.test')

    expect { signup(email_address: 'NOVO@futebol.test') }.not_to change(Core::User, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('já está em uso')
  end

  it 'answers 422 for a password shorter than 8 characters' do
    signup(password: 'curta', password_confirmation: 'curta')

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('deve ter pelo menos 8 caracteres')
  end

  it 'answers 422 for a malformed email' do
    signup(email_address: 'sem-arroba')

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('não é um e-mail válido')
  end

  it 'answers the 6th signup attempt in 3 minutes with 429' do
    5.times { |n| signup(email_address: "rate#{n}@futebol.test", password: 'x', password_confirmation: 'x') }

    signup

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include('Muitas tentativas')
    expect(Core::User.find_by(email_address: 'novo@futebol.test')).to be_nil
  end
end
