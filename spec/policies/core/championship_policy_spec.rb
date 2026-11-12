require 'rails_helper'

RSpec.describe Core::ChampionshipPolicy do
  subject(:policy) { described_class }

  let(:manager) { create(:user, :manager) }
  let(:other_manager) { create(:user, :manager) }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:own_record) { create(:championship, manager:) }
  let(:foreign_record) { create(:championship, manager: other_manager) }

  it { expect(Pundit.policy(nil, Core::Championship.new)).to be_a(described_class) }

  permissions :index?, :create?, :new? do
    it('grants an admin') { expect(policy).to permit(admin, Core::Championship) }
    it('grants an approved manager') { expect(policy).to permit(manager, Core::Championship) }
    it('denies a regular user') { expect(policy).not_to permit(regular_user, Core::Championship) }
  end

  it_behaves_like 'a championship-scoped policy'

  permissions :destroy_all? do
    it('grants an admin') { expect(policy).to permit(admin, Core::Championship) }
    it('denies a manager') { expect(policy).not_to permit(manager, Core::Championship) }
  end

  describe 'Scope' do
    before { own_record && foreign_record }

    it 'lists only managed championships for a manager' do
      expect(described_class::Scope.new(manager, Core::Championship.all).resolve).to contain_exactly(own_record)
    end
  end
end
