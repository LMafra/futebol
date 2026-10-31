require 'rails_helper'

RSpec.describe Cartola::CalculatePreviewService do
  let(:rules) do
    create(:cartola_scoring_rule, goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
  end
  let(:striker) { create(:player, position: 'ATA') }
  let(:midfielder) { create(:player, position: 'MEI') }
  let(:keeper) { create(:player, position: 'GOL') }
  let(:lineup) { create(:cartola_lineup, players: [striker, midfielder, keeper]) }
  let(:stats) do
    {
      striker.id => { goals: 2, yellow_cards: 1 },
      midfielder.id => { assists: 1, red_cards: 1 }
    }
  end

  def preview = described_class.call(lineup:, stats:, rules:)

  it 'returns an immutable PreviewResult built with Data.define' do
    result = preview

    expect(Cartola::PreviewResult.superclass).to eq(Data)
    expect(result).to be_a(Cartola::PreviewResult)
    expect(result).to be_frozen
    expect(result.player_points).to be_frozen
    expect { result.instance_variable_set(:@total, 0) }.to raise_error(FrozenError)
  end

  it 'scores every lineup player and sums the total' do
    result = preview

    expect(result.player_points).to eq(striker.id => 15, midfielder.id => 2, keeper.id => 0)
    expect(result.total).to eq(17)
  end

  it 'is a dry-run: player_scores count is 0 before and after' do
    lineup

    expect(Cartola::PlayerScore.count).to eq(0)
    expect { preview }.not_to change(Cartola::PlayerScore, :count)
    expect(Cartola::PlayerScore.count).to eq(0)
  end

  it 'issues no INSERT, UPDATE or DELETE at all' do
    lineup
    rules
    writes = []
    callback = ->(*, payload) { writes << payload[:sql] if payload[:sql].match?(/\A\s*(INSERT|UPDATE|DELETE)/i) }

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { preview }

    expect(writes).to be_empty
  end

  it 'defaults to the padrao Cartola rule' do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 10, assist_points: 0,
                                  yellow_card_penalty: 0, red_card_penalty: 0)

    expect(described_class.call(lineup:, stats:).total).to eq(20)
  end
end
