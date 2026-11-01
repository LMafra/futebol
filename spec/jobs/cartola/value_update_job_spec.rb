require 'rails_helper'

RSpec.describe Cartola::ValueUpdateJob do
  let(:championship) { create(:championship, cartola_base_player_value: 5) }
  let(:match) { create(:match, championship:) }
  let(:token) { SecureRandom.uuid }

  def score(points, base_value: 10, played: true, in_match: match, player: create(:player, base_value:))
    create(:cartola_player_score, match: in_match, points:, played:, player:).player
  end

  def value_of(player) = Cartola::PlayerValue.find_by!(player:, championship:).value

  it 're-prices the players who played with Cartola::Valuation and records the inputs in the history' do
    star = score(8, base_value: 5)
    base_priced = score(-2, base_value: nil)

    described_class.perform_now(match.id, token)

    expect(value_of(star)).to eq(BigDecimal('6.44'))
    expect(value_of(base_priced)).to eq(BigDecimal('3.94'))
    expect(Cartola::PlayerValueHistory.find_by!(player: star, scoring_token: token))
      .to have_attributes(previous_value: 5, value: BigDecimal('6.44'), score: 8, expected_score: BigDecimal('2.25'),
                          games_played: 1, average_score: 8, match_id: match.id)
  end

  it 'leaves the players who did not play unpriced' do
    player = score(0, played: false)

    described_class.perform_now(match.id, token)

    expect(Cartola::PlayerValue.find_by(player:)).to be_nil
  end

  it "prices on the player's own points, without the captain bonus" do
    captain = score(8, base_value: 5)
    create(:cartola_lineup, championship:, players: [captain], captain:)

    described_class.perform_now(match.id, token)

    expect(value_of(captain)).to eq(BigDecimal('6.44'))
  end

  it 'counts the games already priced in the championship for the history weight and the average' do
    player = create(:player, base_value: 15)
    3.times do |index|
      earlier = create(:match, championship:)
      score(index * 2, in_match: earlier, player:)
      described_class.perform_now(earlier.id, SecureRandom.uuid)
    end
    current = value_of(player)
    score(5, player:)

    described_class.perform_now(match.id, token)

    history = Cartola::PlayerValueHistory.find_by!(player:, scoring_token: token)
    expect(history).to have_attributes(games_played: 4, average_score: BigDecimal('2.75'), previous_value: current)
    expect(history.value).to eq(Cartola::Valuation.new_price(current:, initial: 15, score: 5, games_played: 4))
  end

  it 'starts from the current value, not the base value' do
    player = score(5, base_value: 15)
    create(:cartola_player_value, player:, championship:, value: 20)

    described_class.perform_now(match.id, token)

    expect(value_of(player)).to eq(19)
  end

  it 'ignores discarded scores' do
    kept = score(10)
    create(:cartola_player_score, match:, points: 100, played: true, player: create(:player)).discard

    described_class.perform_now(match.id, token)

    expect(Cartola::PlayerValue.pluck(:player_id)).to eq([kept.id])
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
