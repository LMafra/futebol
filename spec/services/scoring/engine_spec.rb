require 'rails_helper'

RSpec.describe Scoring::Engine do
  let(:bolao_rules) { Bolao::ScoringRule.new(exact_score_points: 10, winner_points: 5) }
  let(:cartola_rules) do
    Cartola::ScoringRule.new(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
  end

  describe '.scorer_for' do
    it 'picks the Bolão strategy' do
      expect(described_class.scorer_for(:bolao)).to eq(Scoring::BolaoScorer)
    end

    it 'picks the Cartola strategy' do
      expect(described_class.scorer_for('cartola')).to eq(Cartola::Scorer)
    end

    it 'falls back to the default (null) strategy for unknown or missing games' do
      expect(described_class.scorer_for(:simulador)).to eq(Scoring::NullScorer)
      expect(described_class.scorer_for(nil)).to eq(Scoring::NullScorer)
    end
  end

  describe '.score' do
    it 'scores a Cartola scout line: goals and assists minus card penalties' do
      stats = { goals: 2, assists: 1, yellow_cards: 1, red_cards: 0 }

      expect(described_class.score(:cartola, stats:, rules: cartola_rules)).to eq(20)
    end

    it 'scores a Bolão guess against the result' do
      expect(described_class.score(:bolao, guess: [2, 1], result: [2, 1], rules: bolao_rules)).to eq(10)
    end

    it 'scores 0 by default for games without a strategy' do
      expect(described_class.score(:simulador, guess: [2, 1], result: [2, 1], rules: bolao_rules)).to eq(0)
    end
  end

  describe '.points_for (Bolão, 2 faixas)' do
    def prediction(home_guess, away_guess) = Struct.new(:home_guess, :away_guess, :pool).new(home_guess, away_guess)

    {
      [[2, 1], [2, 1]] => 10, # exact score
      [[3, 2], [2, 1]] => 5,  # winner, same goal difference: no separate band any more
      [[3, 1], [2, 1]] => 5,  # winner only
      [[1, 1], [0, 0]] => 5,  # draw, not exact: counts as winner
      [[0, 1], [2, 1]] => 0   # wrong
    }.each do |((home_guess, away_guess), (home, away)), points|
      it "gives #{points} for #{home_guess}x#{away_guess} against #{home}x#{away}" do
        expect(described_class.points_for(prediction: prediction(home_guess, away_guess), home:, away:,
                                          rules: bolao_rules)).to eq(points)
      end
    end

    it 'defaults to Bolao::ScoringRule.for(prediction.pool)' do
      pool = create(:bolao_pool)
      create(:bolao_scoring_rule, pool_id: nil)
      create(:bolao_scoring_rule, pool_id: pool.id, exact_score_points: 12, winner_points: 4)
      pooled = Struct.new(:home_guess, :away_guess, :pool).new(2, 1, pool)

      expect(described_class.points_for(prediction: pooled, home: 2, away: 1)).to eq(12)
    end
  end
end
