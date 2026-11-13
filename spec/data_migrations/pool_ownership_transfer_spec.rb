require 'rails_helper'

RSpec.describe Bolao::PoolOwnershipTransfer do
  let(:migration) { described_class.new(ActiveRecord::Base.connection) }
  let(:manager) { create(:user, :manager) }
  let(:creator) { create(:user) }
  let!(:managed_pool) do
    create(:bolao_pool, owner: creator, championship: create(:championship, manager:))
      .tap { |pool| pool.memberships.create!(user: creator, joined_at: 2.days.ago) }
  end
  let!(:admin_pool) { create(:bolao_pool, owner: creator) }

  it 'passes each pool to the gestor of its championship and keeps the old owner as a member' do
    migration.up

    expect(managed_pool.reload.owner).to eq(manager)
    expect(managed_pool.members).to contain_exactly(creator)
    expect(admin_pool.reload.owner).to eq(creator)
  end

  it 'adds the old owner as a member when he was not one' do
    pool = create(:bolao_pool, owner: creator, championship: create(:championship, manager:))

    migration.up

    expect(pool.reload.members).to contain_exactly(creator)
  end

  it 'gives the pool back to the earliest member on down' do
    managed_pool.memberships.create!(user: create(:user), joined_at: 1.day.ago)
    migration.up

    migration.down

    expect(managed_pool.reload.owner).to eq(creator)
  end
end
