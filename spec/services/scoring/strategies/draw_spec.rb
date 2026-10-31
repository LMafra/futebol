require 'rails_helper'

RSpec.describe Scoring::Strategies::Draw do
  it { expect(described_class.kind).to eq(:draw) }

  it 'applies when guess and result are both draws' do
    expect(described_class.applies?([1, 1], [0, 0])).to be(true)
  end

  it 'does not apply when either side has a winner' do
    expect(described_class.applies?([1, 1], [2, 1])).to be(false)
    expect(described_class.applies?([2, 1], [1, 1])).to be(false)
  end
end
