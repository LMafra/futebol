require 'rails_helper'

RSpec.describe Core::AuditLogPolicy do
  it { expect(Pundit.policy(nil, Core::AuditLog.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy', allowed_for_admin: %i[index? show?]
end
