require 'rails_helper'

RSpec.describe Scoring::Strategies::WinnerAndGoalDiff do
  it { expect(described_class.kind).to eq(:winner_and_goal_diff) }

  it 'applies when the winner and the goal difference match' do
    expect(described_class.applies?([3, 2], [2, 1])).to be(true)
    expect(described_class.applies?([0, 2], [1, 3])).to be(true)
  end

  it 'does not apply to a different difference, a different winner or draws' do
    expect(described_class.applies?([3, 1], [2, 1])).to be(false)
    expect(described_class.applies?([1, 2], [2, 1])).to be(false)
    expect(described_class.applies?([1, 1], [0, 0])).to be(false)
  end
end
