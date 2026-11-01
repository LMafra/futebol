require 'rails_helper'

RSpec.describe Cartola::LineupPolicy do
  subject(:policy) { described_class }

  let(:owner) { create(:user) }
  let(:lineup) { build(:cartola_lineup, squad: create(:cartola_squad, user: owner)) }

  permissions :update?, :edit? do
    it('grants the squad owner') { expect(policy).to permit(owner, lineup) }
    it('denies another user') { expect(policy).not_to permit(create(:user), lineup) }
  end

  permissions :destroy? do
    it('grants the squad owner a saved lineup') { expect(policy).to permit(owner, lineup.tap(&:save!)) }
    it('has nothing to undo before the lineup is saved') { expect(policy).not_to permit(owner, lineup) }
    it('denies another user') { expect(policy).not_to permit(create(:user), lineup.tap(&:save!)) }
  end

  it 'lets an admin read but not edit or undo' do
    admin = create(:user, :admin)

    expect(policy.new(admin, lineup.tap(&:save!)))
      .to have_attributes(show?: true, update?: false, edit?: false, destroy?: false)
  end
end
