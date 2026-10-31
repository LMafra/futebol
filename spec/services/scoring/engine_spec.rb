require 'rails_helper'

RSpec.describe Scoring::Engine do
  let(:bolao_rules) { { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 } }
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

  describe '.points_for (Bolão)' do
    def prediction(home_guess, away_guess) = Struct.new(:home_guess, :away_guess, :pool).new(home_guess, away_guess)

    {
      [[2, 1], [2, 1]] => 10, # exact score
      [[3, 2], [2, 1]] => 7,  # winner + goal difference
      [[1, 0], [2, 1]] => 7,  # winner + goal difference (spec §7)
      [[3, 1], [2, 1]] => 5,  # winner only
      [[1, 1], [0, 0]] => 3,  # draw, not exact
      [[0, 1], [2, 1]] => 0   # wrong
    }.each do |((home_guess, away_guess), (home, away)), points|
      it "gives #{points} for #{home_guess}x#{away_guess} against #{home}x#{away}" do
        expect(described_class.points_for(prediction: prediction(home_guess, away_guess), home:, away:,
                                          rules: bolao_rules)).to eq(points)
      end
    end

    it 'applies custom rules injected for a pool' do
      rules = bolao_rules.merge(exact_score: 25, draw: 1)

      expect(described_class.points_for(prediction: prediction(2, 1), home: 2, away: 1, rules:)).to eq(25)
      expect(described_class.points_for(prediction: prediction(1, 1), home: 0, away: 0, rules:)).to eq(1)
    end

    it 'defaults to Bolao::ScoringRule.for(prediction.pool)' do
      bolao_rules.each { |kind, points| create(:bolao_scoring_rule, pool_id: nil, kind:, points:) }
      create(:bolao_scoring_rule, pool_id: 5, kind: 'exact_score', points: 12)
      pooled = Struct.new(:home_guess, :away_guess, :pool).new(2, 1, Struct.new(:id).new(5))

      expect(described_class.points_for(prediction: pooled, home: 2, away: 1)).to eq(12)
    end
  end
end
