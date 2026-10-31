require 'rails_helper'

RSpec.describe Core::AuditLog do
  it 'requires an ip_address' do
    expect(build(:audit_log, ip_address: nil)).not_to be_valid
  end

  it 'stores the ip_address as inet and links the actor' do
    log = create(:audit_log, user: create(:user), ip_address: '200.10.20.30')

    expect(log.reload.ip_address.to_s).to eq('200.10.20.30')
    expect(log.user).to be_present
  end
end
