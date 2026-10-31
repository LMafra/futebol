require 'rails_helper'

RSpec.describe Cartola::PlayerScore do
  it 'stores points with 2 decimals per player and match' do
    score = create(:cartola_player_score, points: 12.5)

    expect(score.reload.points).to eq(BigDecimal('12.5'))
  end

  it 'soft deletes with discard and keeps the row' do
    score = create(:cartola_player_score)

    score.discard

    expect(described_class.kept).to be_empty
    expect(described_class.with_discarded.count).to eq(1)
  end

  it 'allows a single kept score per player and match' do
    score = create(:cartola_player_score)
    duplicate = build(:cartola_player_score, player: score.player, match: score.match)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)

    score.discard
    expect(duplicate.save).to be(true)
  end
end
