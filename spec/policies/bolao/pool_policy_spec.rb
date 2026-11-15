require 'rails_helper'

RSpec.describe Bolao::PoolPolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:pool) { create(:bolao_pool, owner:).tap { |pool| pool.memberships.create!(user: member) } }

  it { expect(Pundit.policy(nil, Bolao::Pool.new)).to be_a(described_class) }

  permissions :index?, :join? do
    it('grants any signed-in user') { expect(policy).to permit(outsider, Bolao::Pool) }
    it('denies an anonymous visitor') { expect(policy).not_to permit(nil, Bolao::Pool) }
  end

  permissions :create?, :new? do
    let(:manager) { create(:user, :manager) }

    it('grants an admin') { expect(policy).to permit(admin, Bolao::Pool.new(championship: create(:championship))) }
    it('denies a user') { expect(policy).not_to permit(outsider, Bolao::Pool) }
    it('denies an anonymous visitor') { expect(policy).not_to permit(nil, Bolao::Pool) }

    it 'grants a gestor only on his own championship' do
      expect(policy).to permit(manager, Bolao::Pool.new(championship: create(:championship, manager:)))
      expect(policy).not_to permit(manager, Bolao::Pool.new(championship: create(:championship)))
    end
  end

  permissions :show? do
    it('grants a member') { expect(policy).to permit(member, pool) }
    it('grants an admin') { expect(policy).to permit(admin, pool) }
    it('denies a non-member') { expect(policy).not_to permit(outsider, pool) }
    it('denies an anonymous visitor') { expect(policy).not_to permit(nil, pool) }
  end

  permissions :destroy? do
    it('grants the owner') { expect(policy).to permit(owner, pool) }
    it('grants an admin') { expect(policy).to permit(admin, pool) }
    it('denies a member who is not the owner') { expect(policy).not_to permit(member, pool) }
  end

  permissions :update?, :edit?, :destroy_all? do
    it('grants an admin') { expect(policy).to permit(admin, pool) }
    it('denies the owner') { expect(policy).not_to permit(owner, pool) }
  end

  describe 'Scope' do
    def resolve(user) = described_class::Scope.new(user, Bolao::Pool.all).resolve

    it 'resolves only the pools the user belongs to' do
      other = create(:bolao_pool)

      expect(resolve(member)).to contain_exactly(pool)
      expect(resolve(admin)).to contain_exactly(pool, other)
      expect(resolve(outsider)).to be_empty
      expect(resolve(nil)).to be_empty
    end
  end
end
