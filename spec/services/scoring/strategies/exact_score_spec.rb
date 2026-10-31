require 'rails_helper'

RSpec.describe Scoring::Strategies::ExactScore do
  it { expect(described_class.kind).to eq(:exact_score) }

  it 'applies only when both scores match' do
    expect(described_class.applies?([2, 1], [2, 1])).to be(true)
    expect(described_class.applies?([0, 0], [0, 0])).to be(true)
    expect(described_class.applies?([2, 0], [2, 1])).to be(false)
  end
end
