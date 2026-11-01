require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:user) { create(:user) }

  it 'redirects anonymous visitors to the login page' do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it 'renders the login page without a session' do
    get new_session_path

    expect(response).to have_http_status(:ok)
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
    expect(flash[:alert]).to be_present
    expect(user.sessions).to be_empty
  end

  it 'signs out and destroys the session' do
    sign_in(user)

    expect { delete session_path }.to change { user.sessions.count }.from(1).to(0)
    expect(response).to redirect_to(new_session_path)
  end
end
