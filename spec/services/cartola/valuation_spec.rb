require 'rails_helper'

RSpec.describe Cartola::Valuation do
  def price(current:, score:, games_played:, initial: current)
    described_class.new_price(current: BigDecimal(current.to_s), initial: BigDecimal(initial.to_s),
                              score: BigDecimal(score.to_s), games_played:)
  end

  it 'prices scenario A of the tip: C$ 5, initial 5, 8 points -> C$ 6.44' do
    expect(price(current: 5, score: 8, games_played: 1)).to eq(BigDecimal('6.44'))
  end

  it 'prices scenario B with the right value: C$ 20, initial 15, 5 points from the 4th game -> C$ 18.69' do
    expect(price(current: 20, initial: 15, score: 5, games_played: 4)).to eq(BigDecimal('18.69'))
  end

  it 'weighs the historical term 0 on the 1st game, half on the 2nd and 3rd and fully from the 4th' do
    expected = (1..5).map { |games_played| described_class.expected_score(current: 20, initial: 15, games_played:) }

    expect(expected).to eq([9, 9.625, 9.625, 10.25, 10.25].map { BigDecimal(_1.to_s) })
  end

  it 'moves at most C$ 5 per game' do
    expect(price(current: 10, score: 100, games_played: 1)).to eq(15)
    expect(price(current: 10, score: -100, games_played: 1)).to eq(5)
  end

  it 'never prices below C$ 0.50' do
    expect(price(current: 1, score: -10, games_played: 1)).to eq(BigDecimal('0.5'))
  end
end
