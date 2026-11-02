require 'rails_helper'

RSpec.describe Users::AnonymizeService do
  let(:admin) { create(:user, :admin) }
  let!(:user) do
    create(:user, name: 'Maria da Silva', email_address: 'maria@futebol.test', cpf: '123.456.789-09',
                  password: 'senha-original')
  end

  def anonymize = described_class.call(user:, actor: admin, ip_address: '203.0.113.7')

  it 'anonymizes name, email and cpf, keeps the id and sets active: false' do
    original_id = user.id

    anonymize

    reloaded = Core::User.find(original_id)
    expect(reloaded.id).to eq(original_id)
    expect(reloaded.name).to eq('Usuário anonimizado')
    expect(reloaded.email_address).to match(/\Aanon-\h{8}-\h{4}-\h{4}-\h{4}-\h{12}@invalid\z/)
    expect(reloaded.cpf).to be_nil
    expect(reloaded.active).to be(false)
    expect(reloaded.anonymized_at).to be_present
  end

  it 'revokes the public-profile consent' do
    user.update!(public_profile_consented_at: Time.current)

    anonymize

    expect(user.reload).not_to be_public_profile_consented
    expect(user.public_display_name).to eq('Participante')
  end

  it 'leaves no original personal data on the record' do
    anonymize

    values = Core::User.find(user.id).attributes.values.map(&:to_s)
    expect(values).not_to include('Maria da Silva', 'maria@futebol.test', '12345678909')
  end

  it 'invalidates the password and destroys every session' do
    user.sessions.create!(ip_address: '127.0.0.1')
    user.sessions.create!(ip_address: '127.0.0.2')

    expect { anonymize }.to change { user.sessions.count }.from(2).to(0)
    expect(Core::User.authenticate_by(email_address: 'maria@futebol.test', password: 'senha-original')).to be_nil
    expect(Core::User.find(user.id).authenticate('senha-original')).to be(false)
  end

  it 'records an anonymize AuditLog with actor and ip_address, without PII' do
    anonymize

    log = Core::AuditLog.sole
    expect(log).to have_attributes(action: 'anonymize', user: admin, auditable: user)
    expect(log.ip_address.to_s).to eq('203.0.113.7')
    expect(log.metadata.to_s).not_to include('maria')
  end

  it 'is idempotent: a second call is a no-op' do
    expect { 2.times { anonymize } }.to change(Core::AuditLog, :count).by(1)
  end

  it 'rolls everything back when the AuditLog cannot be written' do
    user.sessions.create!(ip_address: '127.0.0.1')

    expect { described_class.call(user:, actor: admin, ip_address: nil) }.to raise_error(ActiveRecord::RecordInvalid)

    reloaded = Core::User.find(user.id)
    expect(reloaded).to have_attributes(name: 'Maria da Silva', email_address: 'maria@futebol.test', active: true)
    expect(reloaded.sessions.count).to eq(1)
  end
end
