require 'rails_helper'

RSpec.describe Bolao::Pool do
  it 'assigns a 6-character code without ambiguous characters on create' do
    expect(create(:bolao_pool).code).to match(/\A[A-HJ-NP-Z2-9]{6}\z/)
  end

  it 'keeps an explicit code' do
    expect(create(:bolao_pool, code: 'DEMO01').code).to eq('DEMO01')
  end

  it 'rejects a duplicated code' do
    existing = create(:bolao_pool)

    expect(build(:bolao_pool, code: existing.code)).not_to be_valid
  end

  it 'adds the owner as a member on create' do
    pool = create(:bolao_pool)

    expect(pool.members).to contain_exactly(pool.owner)
    expect(pool).to be_member(pool.owner)
  end

  it 'normalizes codes typed by hand' do
    expect(described_class.normalize_code(' k7p2qd ')).to eq('K7P2QD')
  end
end
