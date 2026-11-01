require 'rails_helper'

RSpec.describe Bolao::ScoringRule do
  let(:pool) { create(:bolao_pool) }
  let(:other_pool) { create(:bolao_pool) }
  let(:rule) { described_class.new(exact_score_points: 10, winner_points: 5) }

  describe '#points_for' do
    it 'placar exato → exact_score_points' do
      expect(rule.points_for(2, 1, 2, 1)).to eq(points: 10, result: :exact)
    end

    it 'vencedor certo com placar errado → winner_points' do
      expect(rule.points_for(3, 0, 2, 1)).to eq(points: 5, result: :winner)
    end

    it 'empate certo com placar errado → winner_points (não é faixa separada)' do
      expect(rule.points_for(1, 1, 0, 0)).to eq(points: 5, result: :winner)
    end

    it 'erro → 0' do
      expect(rule.points_for(0, 1, 2, 1)).to eq(points: 0, result: :miss)
    end
  end

  it 'defaults to 10 (exact) / 5 (winner)' do
    expect(described_class.new).to have_attributes(exact_score_points: 10, winner_points: 5)
  end

  it 'requires exact_score_points >= winner_points >= 0' do
    expect(build(:bolao_scoring_rule, exact_score_points: 5, winner_points: 5)).to be_valid
    expect(build(:bolao_scoring_rule, exact_score_points: 4, winner_points: 5)).not_to be_valid
    expect(build(:bolao_scoring_rule, winner_points: -1)).not_to be_valid
  end

  it 'allows one rule per scope and never both a pool and a championship' do
    create(:bolao_scoring_rule, pool:)

    expect(build(:bolao_scoring_rule, pool:)).not_to be_valid
    expect(build(:bolao_scoring_rule, pool: other_pool)).to be_valid
    expect(build(:bolao_scoring_rule, pool: other_pool, championship: other_pool.championship)).not_to be_valid
  end

  describe 'database constraints' do
    it 'rejects winner_points above exact_score_points' do
      expect { create(:bolao_scoring_rule).update_columns(winner_points: 11) }
        .to raise_error(ActiveRecord::StatementInvalid, /bolao_scoring_rules_bands_ordered/)
    end

    it 'rejects a rule scoped to a pool and a championship at once' do
      expect { create(:bolao_scoring_rule, pool:).update_columns(championship_id: pool.championship_id) }
        .to raise_error(ActiveRecord::StatementInvalid, /bolao_scoring_rules_single_scope/)
    end

    it 'raises RecordNotUnique for a second global rule (NULL scope)' do
      create(:bolao_scoring_rule)

      expect { build(:bolao_scoring_rule).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.for / .by_pool' do
    let!(:global) { create(:bolao_scoring_rule, exact_score_points: 10, winner_points: 5) }

    it 'falls back to the defaults when no rule exists' do
      global.destroy!

      expect(described_class.for(pool)).to have_attributes(exact_score_points: 10, winner_points: 5)
    end

    it 'resolves pool override, then championship rule, then global' do
      championship_rule = create(:bolao_scoring_rule, championship: pool.championship, exact_score_points: 8,
                                                      winner_points: 4)
      pool_rule = create(:bolao_scoring_rule, pool:, exact_score_points: 15, winner_points: 6)
      same_championship = create(:bolao_pool, championship: pool.championship)

      expect(described_class.for(pool)).to eq(pool_rule)
      expect(described_class.for(same_championship)).to eq(championship_rule)
      expect(described_class.for(other_pool)).to eq(global)
      expect(described_class.for(nil)).to eq(global)
    end

    it 'resolves several pools in one query' do
      create(:bolao_scoring_rule, pool:, exact_score_points: 15, winner_points: 6)
      pools = [pool, other_pool, pool]

      queries = []
      counter = ->(*, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }
      rules = ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { described_class.by_pool(pools) }

      expect(queries.size).to eq(1)
      expect(rules.transform_values(&:exact_score_points)).to eq(pool.id => 15, other_pool.id => 10)
    end
  end
end
