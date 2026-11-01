require 'rails_helper'

RSpec.describe 'Passwords', type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  it 'envia o e-mail de redefinição em português' do
    perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }

    expect(flash[:notice]).to start_with('Se houver uma conta com esse e-mail')
    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq('Redefina sua senha')
    expect(mail.text_part.body.to_s).to include('Você pode redefinir sua senha', 'O link expira em 15 minutos')
  end

  it 'avisa quando o link é inválido' do
    get edit_password_path('token-invalido')

    expect(response).to redirect_to(new_password_path)
    expect(flash[:alert]).to eq('O link para redefinir a senha é inválido ou expirou.')
  end

  it 'redefine a senha e avisa quando a confirmação não confere' do
    token = user.password_reset_token

    patch password_path(token), params: { password: 'nova-senha-123', password_confirmation: 'outra' }
    expect(flash[:alert]).to eq('As senhas não conferem.')

    patch password_path(token), params: { password: 'nova-senha-123', password_confirmation: 'nova-senha-123' }
    expect(flash[:notice]).to eq('Senha redefinida.')
  end
end
