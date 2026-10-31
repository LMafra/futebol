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
end
