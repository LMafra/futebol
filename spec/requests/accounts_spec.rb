require 'rails_helper'

RSpec.describe 'Minha conta', type: :request do
  let(:user) { create(:user, name: 'Lucas Mafra', email_address: 'lucas@futebol.test') }

  it 'exige login' do
    get account_path

    expect(response).to redirect_to(new_session_path)
  end

  context 'with a session' do
    before { sign_in(user) }

    it 'mostra nome, e-mail e o nome público, sem campos editáveis de dados' do
      get '/minha-conta'

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('[data-role="account-data"]').text.squish)
        .to include('Lucas Mafra', 'lucas@futebol.test', 'Participante')
      expect(page.css('form input[type="text"], form input[type="email"]')).to be_empty
      expect(page.at_css('input[type="checkbox"][name="public_profile_consent"]')['checked']).to be_nil
    end

    it 'liga e desliga o consentimento, registrando AuditLog com IP a cada mudança' do
      expect { patch account_path, params: { public_profile_consent: '1' } }.to change(Core::AuditLog, :count).by(1)
      expect(response).to redirect_to(account_path)
      expect(user.reload.public_display_name).to eq('Lucas M.')
      expect(Core::AuditLog.last).to have_attributes(action: 'user.public_profile_consent_granted', user:)

      expect { patch account_path, params: { public_profile_consent: '1' } }.not_to change(Core::AuditLog, :count)

      expect { patch account_path, params: { public_profile_consent: '0' } }.to change(Core::AuditLog, :count).by(1)
      expect(user.reload).not_to be_public_profile_consented
      log = Core::AuditLog.last
      expect([log.action, log.ip_address.to_s]).to eq(['user.public_profile_consent_revoked', '127.0.0.1'])
    end
  end
end
