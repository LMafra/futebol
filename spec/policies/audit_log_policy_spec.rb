require 'rails_helper'

RSpec.describe AuditLogPolicy do
  it { expect(described_class.superclass).to eq(ApplicationPolicy) }

  it_behaves_like 'an admin-only policy', allowed_for_admin: %i[index? show?]
end
