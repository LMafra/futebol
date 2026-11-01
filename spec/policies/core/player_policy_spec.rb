require 'rails_helper'

RSpec.describe Core::PlayerPolicy do
  it { expect(Pundit.policy(nil, Core::Player.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy'
end
