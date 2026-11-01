require 'rails_helper'

RSpec.describe Cartola::SquadPolicy do
  it { expect(Pundit.policy(nil, Cartola::Squad.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy'
end
