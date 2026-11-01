require 'rails_helper'

RSpec.describe Cartola::Scorer do
  let(:rules) do
    build(:cartola_scoring_rule, goal_points: 8, assist_points: 5, clean_sheet_points: 5, penalty_save_points: 7,
                                 save_points: 1.5, yellow_card_penalty: 1, red_card_penalty: 3, own_goal_penalty: 3,
                                 played_points: 1, highlight_points: 5)
  end

  it 'soma G, A, SG, DP e DE, desconta CA, CV e GC e adiciona Jogou e Destaque' do
    stats = { goals: 1, assists: 2, clean_sheet: true, penalty_saves: 1, saves: 2, yellow_cards: 1, red_cards: 0,
              own_goals: 0, played: true, highlight: true }

    expect(described_class.points(stats:, rules:)).to eq(8 + 10 + 5 + 7 + 3 - 1 + 1 + 5)
  end

  it 'pode ficar negativo' do
    stats = { yellow_cards: 2, red_cards: 1, own_goals: 1, played: true }

    expect(described_class.points(stats:, rules:)).to eq(-2 - 3 - 3 + 1)
  end

  it 'conta chaves ausentes como zero e flags falsas como nada' do
    expect(described_class.points(stats: { clean_sheet: false, highlight: false }, rules:)).to eq(0)
  end
end
