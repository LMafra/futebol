require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:user) { create(:user) }

  it 'redirects anonymous visitors to the login page' do
    get pools_path

    expect(response).to redirect_to(new_session_path)
  end

  it 'renders the login page without a session' do
    get new_session_path

    expect(response).to have_http_status(:ok)
  end

  it 'serves the login page at /entrar too' do
    get login_path

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('main p.uppercase').text).to eq('Craquefy')
    expect(page.at_css('header nav a[href="/entrar"]').text).to eq('Entrar')
    expect(page.at_css('[data-role="account-menu"]')).to be_nil
    expect(page.at_css('footer a[href="/admin"]').text).to eq('Acesso administrativo')
  end

  it 'sends anonymous /admin visitors to /session/new' do
    get '/admin'

    expect(response).to redirect_to(new_session_path)
  end

  it 'shows the account menu and the sign-out button to signed-in users' do
    sign_in(user)
    get pools_path

    page = Nokogiri::HTML(response.body)
    menu = page.at_css('header [data-role="account-menu"]')
    expect(menu.css('a').map(&:text)).to eq(['Minha conta', 'Meus bolões', 'Meu esquadrão', 'Rankings'])
    expect(page.at_css('header form[action="/session"] button').text).to eq('Sair')
    expect(page.at_css('header nav a[href="/entrar"]')).to be_nil
  end

  it 'links the login page to the public signup form' do
    get new_session_path
    expect(response.body).to include(%(href="#{signup_path}">Criar conta</a>))

    get signup_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="user[email_address]"', 'name="user[password_confirmation]"')
  end

  it 'signs in with valid credentials and records the request origin' do
    sign_in(user)

    expect(response).to redirect_to(root_url)
    expect(user.sessions.last.ip_address).to be_present

    get root_path
    expect(response.body).to include(user.email_address)
  end

  it 'rejects invalid credentials' do
    sign_in(user, password: 'wrong-password')

    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to eq('E-mail ou senha incorretos. Tente novamente.')
    expect(user.sessions).to be_empty
  end

  it 'rejects an inactive user even with the right password' do
    user.update!(active: false)
    sign_in(user)

    expect(response).to redirect_to(new_session_path)
    expect(user.sessions).to be_empty
  end

  it 'signs out and destroys the session' do
    sign_in(user)

    expect { delete session_path }.to change { user.sessions.count }.from(1).to(0)
    expect(response).to redirect_to(new_session_path)
  end
end
