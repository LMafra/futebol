require 'rails_helper'

RSpec.describe Core::ScoringRulePolicy do
  it_behaves_like 'an admin-only policy', extra_admin_actions: %i[test?]

  it 'governs the Bolão and Cartola scoring rules' do
    expect(Pundit.policy(nil, Bolao::ScoringRule.new)).to be_a(described_class)
    expect(Pundit.policy(nil, Cartola::ScoringRule.new)).to be_a(described_class)
  end
end
