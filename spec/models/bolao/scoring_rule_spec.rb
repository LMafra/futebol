require 'rails_helper'

RSpec.describe Bolao::ScoringRule do
  let(:pool) { create(:bolao_pool) }
  let(:other_pool) { create(:bolao_pool) }

  it 'defines the four outcome kinds in precedence order' do
    expect(described_class::KINDS).to eq(%w[exact_score winner_and_goal_diff winner draw])
  end

  it 'is valid as a global rule (no pool)' do
    expect(build(:bolao_scoring_rule, pool_id: nil)).to be_valid
  end

  it 'rejects negative points and unknown kinds' do
    expect(build(:bolao_scoring_rule, points: -1)).not_to be_valid
    expect(build(:bolao_scoring_rule, kind: 'own_goal')).not_to be_valid
  end

  it 'rejects a duplicated kind within the same pool' do
    create(:bolao_scoring_rule, pool: pool, kind: 'winner')

    expect(build(:bolao_scoring_rule, pool: pool, kind: 'winner')).not_to be_valid
    expect(build(:bolao_scoring_rule, pool: other_pool, kind: 'winner')).to be_valid
  end

  describe 'database constraints' do
    it 'raises StatementInvalid for points: -1' do
      rule = create(:bolao_scoring_rule)

      expect { rule.update_columns(points: -1) }
        .to raise_error(ActiveRecord::StatementInvalid, /bolao_scoring_rules_points_non_negative/)
    end

    it 'raises StatementInvalid for an unknown kind' do
      rule = create(:bolao_scoring_rule)

      expect { rule.update_columns(kind: 'own_goal') }
        .to raise_error(ActiveRecord::StatementInvalid, /bolao_scoring_rules_kind_valid/)
    end

    it 'raises RecordNotUnique for a duplicated kind in the same pool' do
      create(:bolao_scoring_rule, pool: pool, kind: 'draw')
      duplicate = build(:bolao_scoring_rule, pool: pool, kind: 'draw')

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'raises RecordNotUnique for a duplicated global kind (NULL pool_id)' do
      create(:bolao_scoring_rule, pool_id: nil, kind: 'draw')
      duplicate = build(:bolao_scoring_rule, pool_id: nil, kind: 'draw')

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.for' do
    before do
      { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 }.each do |kind, points|
        create(:bolao_scoring_rule, pool_id: nil, kind:, points:)
      end
    end

    it 'returns the global rules when called without a pool' do
      expect(described_class.for(nil)).to eq(exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3)
    end

    it 'falls back to the global rule when the pool has no override' do
      expect(described_class.for(pool)).to eq(exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3)
    end

    it 'uses the pool override where one exists' do
      create(:bolao_scoring_rule, pool: pool, kind: 'exact_score', points: 15)
      create(:bolao_scoring_rule, pool: other_pool, kind: 'winner', points: 1)

      expect(described_class.for(pool)).to eq(exact_score: 15, winner_and_goal_diff: 7, winner: 5, draw: 3)
    end
  end
end
