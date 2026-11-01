require 'rails_helper'

RSpec.describe Cartola::LineupPolicy do
  subject(:policy) { described_class }

  let(:owner) { create(:user) }
  let(:lineup) { build(:cartola_lineup, squad: create(:cartola_squad, user: owner)) }

  permissions :update?, :edit? do
    it('grants the squad owner') { expect(policy).to permit(owner, lineup) }
    it('denies another user') { expect(policy).not_to permit(create(:user), lineup) }
  end

  it 'lets an admin read but not edit' do
    admin = create(:user, :admin)

    expect(policy.new(admin, lineup)).to have_attributes(show?: true, update?: false, edit?: false)
  end
end
