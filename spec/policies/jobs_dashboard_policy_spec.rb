require 'rails_helper'

RSpec.describe JobsDashboardPolicy do
  subject(:policy) { described_class.new(user, :jobs_dashboard) }

  it 'is the policy Pundit resolves for the dashboard' do
    expect(Pundit.policy(nil, :jobs_dashboard)).to be_a(described_class)
  end

  context 'with an admin' do
    let(:user) { build(:user, :admin) }

    it { expect(policy).to have_attributes(index?: true, show?: true, create?: false, update?: false, destroy?: false) }
  end

  context 'with a regular user' do
    let(:user) { build(:user) }

    it { expect(policy).to have_attributes(index?: false, show?: false) }
  end

  context 'with a visitor' do
    let(:user) { nil }

    it { expect(policy.show?).to be(false) }
  end
end
