require 'rails_helper'

RSpec.describe Core::ChampionshipPolicy do
  it { expect(Pundit.policy(nil, Core::Championship.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy'
end
