require 'rails_helper'

RSpec.describe Core::User do
  it 'is valid with an email and an 8+ character password' do
    expect(build(:user)).to be_valid
  end

  it 'requires a well-formed email address' do
    expect(build(:user, email_address: 'not-an-email')).not_to be_valid
  end

  it 'normalizes and enforces unique email addresses' do
    create(:user, email_address: 'Admin@Futebol.test ')

    duplicate = build(:user, email_address: 'admin@futebol.test')

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email_address]).to be_present
  end

  it 'rejects passwords shorter than 8 characters' do
    expect(build(:user, password: 'short')).not_to be_valid
  end

  it 'is not an admin by default' do
    expect(create(:user).admin?).to be(false)
  end

  it 'authenticates by email and password' do
    user = create(:user)

    expect(described_class.authenticate_by(email_address: user.email_address, password: 'password123')).to eq(user)
    expect(described_class.authenticate_by(email_address: user.email_address, password: 'wrong-pass')).to be_nil
  end

  it 'is active by default and scopes active users' do
    active = create(:user)
    create(:user, active: false)

    expect(described_class.active).to contain_exactly(active)
  end

  it 'stores the cpf as 11 digits and rejects malformed or duplicated ones' do
    expect(create(:user, cpf: '123.456.789-09').cpf).to eq('12345678909')
    expect(build(:user, cpf: '1234')).not_to be_valid
    expect(build(:user, cpf: '12345678909')).not_to be_valid
    expect(build(:user, cpf: nil)).to be_valid
  end

  describe 'database check constraints' do
    it 'blocks a cpf that is not 11 digits' do
      user = create(:user)

      expect { user.update_columns(cpf: '123') }.to raise_error(ActiveRecord::StatementInvalid, /core_users_cpf_digits/)
    end

    it 'blocks an anonymized user that is still active' do
      user = create(:user, cpf: nil)

      expect { user.update_columns(anonymized_at: Time.current) }
        .to raise_error(ActiveRecord::StatementInvalid, /core_users_anonymized_inactive/)
    end
  end
end
