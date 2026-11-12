require 'rails_helper'

RSpec.describe Core::PlayerPolicy do
  subject(:policy) { described_class }

  let(:manager) { create(:user, :manager) }
  let(:other_manager) { create(:user, :manager) }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:own_match) { create(:match, championship: create(:championship, manager:)) }
  let(:foreign_match) { create(:match, championship: create(:championship, manager: other_manager)) }
  let(:own_record) { create(:player, team: own_match.home_team) }
  let(:foreign_record) { create(:player, team: foreign_match.home_team) }

  it { expect(Pundit.policy(nil, Core::Player.new)).to be_a(described_class) }

  permissions :index?, :create?, :new? do
    it('grants an admin') { expect(policy).to permit(admin, Core::Player) }
    it('grants an approved manager') { expect(policy).to permit(manager, Core::Player) }
    it('denies a regular user') { expect(policy).not_to permit(regular_user, Core::Player) }
  end

  it_behaves_like 'a championship-scoped policy'

  describe 'Scope' do
    before { own_record && foreign_record }

    it 'lists players of managed teams for a manager' do
      resolve = described_class::Scope.new(manager, Core::Player.all).resolve

      expect(resolve).to include(own_record)
      expect(resolve).not_to include(foreign_record)
    end
  end
end
