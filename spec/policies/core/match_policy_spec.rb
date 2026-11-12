require 'rails_helper'

RSpec.describe Core::MatchPolicy do
  subject(:policy) { described_class }

  let(:manager) { create(:user, :manager) }
  let(:other_manager) { create(:user, :manager) }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:own_record) { create(:match, championship: create(:championship, manager:)) }
  let(:foreign_record) { create(:match, championship: create(:championship, manager: other_manager)) }

  it { expect(Pundit.policy(nil, Core::Match.new)).to be_a(described_class) }

  permissions :index? do
    it('grants an admin') { expect(policy).to permit(admin, Core::Match) }
    it('grants an approved manager') { expect(policy).to permit(manager, Core::Match) }
    it('denies a regular user') { expect(policy).not_to permit(regular_user, Core::Match) }
  end

  it_behaves_like 'a championship-scoped policy', actions: %i[show?]

  permissions :create?, :update?, :destroy? do
    it('denies even an admin') { expect(policy).not_to permit(admin, own_record) }
  end

  %i[preview? finalize? revert? record_scouts?].each do |action|
    permissions action do
      it('grants an admin') { expect(policy).to permit(admin, own_record) }
      it('denies a manager') { expect(policy).not_to permit(manager, own_record) }
    end
  end

  describe 'Scope' do
    before { own_record && foreign_record }

    it 'lists only managed championship matches for a manager' do
      resolve = described_class::Scope.new(manager, Core::Match.all).resolve

      expect(resolve).to include(own_record)
      expect(resolve).not_to include(foreign_record)
    end
  end
end
