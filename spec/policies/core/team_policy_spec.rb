require 'rails_helper'

RSpec.describe Core::TeamPolicy do
  it { expect(Pundit.policy(nil, Core::Team.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy'
end
