require 'rails_helper'

RSpec.describe Scoring::Strategies::Winner do
  it { expect(described_class.kind).to eq(:winner) }

  it 'applies when the same side wins' do
    expect(described_class.applies?([3, 1], [2, 1])).to be(true)
    expect(described_class.applies?([0, 3], [1, 2])).to be(true)
  end

  it 'does not apply to a different winner or to draws' do
    expect(described_class.applies?([0, 1], [2, 1])).to be(false)
    expect(described_class.applies?([1, 1], [2, 2])).to be(false)
  end
end
