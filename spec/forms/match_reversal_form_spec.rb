require 'rails_helper'

RSpec.describe MatchReversalForm do
  let(:match) do
    create(:match, status: 'scored', home_score: 1, away_score: 0, match_date: 1.day.ago,
                   scores_calculated_at: 1.hour.ago, scoring_token: SecureRandom.uuid)
  end

  it 'requires a justification of at least 20 characters' do
    form = described_class.new(match:, actor: create(:user, :admin), ip_address: '127.0.0.1', reason: 'curto')

    expect(form).not_to be_valid
    expect(form.errors[:reason].first).to include('20')
  end
end
