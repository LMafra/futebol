require 'rails_helper'

RSpec.describe 'Rate limiting on auth endpoints', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  def attempt_login = post(session_path, params: { email_address: user.email_address, password: 'wrong-password' })

  describe 'POST /session' do
    it 'accepts 5 attempts in 3 minutes and answers the 6th with 429' do
      5.times do
        attempt_login
        expect(response).to redirect_to(new_session_path)
      end

      attempt_login

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include('Muitas tentativas. Aguarde alguns minutos e tente novamente.')
    end

    it 'blocks a correct password too once the limit is reached' do
      5.times { attempt_login }

      sign_in(user)

      expect(response).to have_http_status(:too_many_requests)
      expect(user.sessions).to be_empty
    end

    it 'accepts attempts again once the 3-minute window has passed' do
      6.times { attempt_login }
      expect(response).to have_http_status(:too_many_requests)

      travel(3.minutes + 1.second) { attempt_login }

      expect(response).to redirect_to(new_session_path)
    end

    it 'logs the blocked attempt with the client IP' do
      allow(Rails.logger).to receive(:warn).and_call_original
      6.times { attempt_login }

      expect(Rails.logger).to have_received(:warn).with(/rate_limited.*sessions#create.*ip=127\.0\.0\.1/).once
    end
  end

  describe 'POST /passwords' do
    it 'answers the 6th reset request in 3 minutes with 429' do
      5.times do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
      end

      post passwords_path, params: { email_address: user.email_address }

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
