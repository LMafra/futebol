require 'rails_helper'

RSpec.describe Bolao::BetPolicy do
  subject(:policy) { described_class }

  let(:member) { create(:user) }
  let(:pool) { create(:bolao_pool).tap { |pool| pool.memberships.create!(user: member) } }
  let(:own_bet) { build(:bolao_prediction, pool:, user: member) }

  permissions :create?, :update? do
    it('grants a member on their own bet') { expect(policy).to permit(member, own_bet) }

    it 'denies a member on somebody else\'s bet' do
      expect(policy).not_to permit(member, build(:bolao_prediction, pool:, user: pool.owner))
    end

    it 'denies a non-member even on a bet in their name' do
      outsider = create(:user)
      expect(policy).not_to permit(outsider, build(:bolao_prediction, pool:, user: outsider))
    end

    it('denies an anonymous visitor') { expect(policy).not_to permit(nil, own_bet) }
  end

  describe 'Scope' do
    def resolve(user) = described_class::Scope.new(user, Bolao::Prediction.all).resolve

    it 'resolves only the kept bets of the user' do
      mine = create(:bolao_prediction, pool:, user: member)
      create(:bolao_prediction, pool:, user: pool.owner)
      create(:bolao_prediction, pool:, user: member).discard

      expect(resolve(member)).to contain_exactly(mine)
      expect(resolve(nil)).to be_empty
    end
  end
end
