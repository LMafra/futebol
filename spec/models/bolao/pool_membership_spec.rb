require 'rails_helper'

RSpec.describe Bolao::PoolMembership do
  let(:pool) { create(:bolao_pool) }
  let(:user) { create(:user) }

  it 'stamps joined_at on creation' do
    expect(pool.memberships.create!(user:).joined_at).to be_within(1.second).of(Time.current)
  end

  it 'rejects a second membership for the same user and pool' do
    pool.memberships.create!(user:)

    duplicate = pool.memberships.build(user:)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it 'is unique per (pool_id, user_id) in the database' do
    pool.memberships.create!(user:)

    expect { described_class.insert_all!([{ pool_id: pool.id, user_id: user.id, joined_at: Time.current }]) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'lets the same user join different pools' do
    pool.memberships.create!(user:)

    expect(create(:bolao_pool).memberships.build(user:)).to be_valid
  end
end
