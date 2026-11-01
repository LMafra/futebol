require 'rails_helper'

RSpec.describe Cartola::ValueUpdateJob do
  let(:championship) { create(:championship, cartola_base_player_value: 5) }
  let(:match) { create(:match, championship:) }
  let(:token) { SecureRandom.uuid }

  def score(points, base_value: 10)
    create(:cartola_player_score, match:, points:, player: create(:player, base_value:)).player
  end

  def value_of(player) = Cartola::PlayerValue.find_by!(player:, championship:).value

  describe '.new_value' do
    it 'moves the value by (score - average)%' do
      expect(described_class.new_value(BigDecimal(10), score: 15, average: 5)).to eq(11)
      expect(described_class.new_value(BigDecimal(10), score: 2, average: 5)).to eq(BigDecimal('9.7'))
    end

    it 'caps the change at 20% per round' do
      expect(described_class.new_value(BigDecimal(10), score: 80, average: 5)).to eq(12)
      expect(described_class.new_value(BigDecimal(10), score: -60, average: 5)).to eq(8)
    end
  end

  it 're-prices every scored player against the match average and records the history' do
    star = score(25)
    average_player = score(10, base_value: nil)
    flop = score(-5)

    described_class.perform_now(match.id, token)

    expect(value_of(star)).to eq(BigDecimal('11.5'))
    expect(value_of(average_player)).to eq(5)
    expect(value_of(flop)).to eq(BigDecimal('8.5'))
    history = Cartola::PlayerValueHistory.find_by!(player: star, scoring_token: token)
    expect(history).to have_attributes(previous_value: 10, value: BigDecimal('11.5'), score: 25, average_score: 10,
                                       match_id: match.id)
  end

  it 'starts from the current value, not the base value' do
    player = score(30)
    score(10)
    create(:cartola_player_value, player:, championship:, value: 20)

    described_class.perform_now(match.id, token)

    expect(value_of(player)).to eq(22)
  end

  it 'ignores discarded scores' do
    kept = score(10)
    create(:cartola_player_score, match:, points: 100, player: create(:player)).discard

    described_class.perform_now(match.id, token)

    expect(value_of(kept)).to eq(10)
    expect(Cartola::PlayerValue.count).to eq(1)
  end

  it 'is a no-op on a retry with the same scoring token' do
    player = score(20)
    score(0)
    described_class.perform_now(match.id, token)

    expect { described_class.perform_now(match.id, token) }.not_to(change { value_of(player) })
    expect(Cartola::PlayerValueHistory.where(scoring_token: token).count).to eq(2)
  end

  it 'does nothing for a match without player scores' do
    expect { described_class.perform_now(match.id, token) }.not_to change(Cartola::PlayerValue, :count)
  end

  it 'is undone by a Reversal of the same Scoring' do
    player = score(20)
    score(0)
    described_class.perform_now(match.id, token)

    Cartola::PlayerValue.revert!(token)

    expect(value_of(player)).to eq(10)
    expect(Cartola::PlayerValueHistory.where(scoring_token: token)).to be_empty
  end

  it 'is enqueued by ProcessMatchPointsJob after the Scoring' do
    finished = create(:match, championship:, status: 'finished', home_score: 1, away_score: 0,
                              match_date: 1.hour.ago)

    expect { ProcessMatchPointsJob.perform_now(finished.id, token) }
      .to have_enqueued_job(described_class).with(finished.id, token)
  end
end
