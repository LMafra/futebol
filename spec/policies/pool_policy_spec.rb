require 'rails_helper'

RSpec.describe PoolPolicy do
  it { expect(described_class.superclass).to eq(ApplicationPolicy) }

  it_behaves_like 'an admin-only policy'
end
