require 'rails_helper'

RSpec.describe MatchFinalizationForm do
  let(:championship) { create(:championship) }
  let(:match) { create(:match, championship:, status: 'live', match_date: 1.hour.ago) }

  before do
    create(:cartola_player_score, match:, player: create(:player, team: match.home_team), goals: 1)
  end

  it 'exposes the pool impact summary for the finalize preview' do
    pool = create(:bolao_pool, championship:)
    2.times { Bolao::PoolMembership.create!(pool:, user: create(:user), joined_at: Time.current) }

    form = described_class.new(match:)

    expect(form.pool_participants_count).to eq(2)
    expect(form.impact_summary).to eq('2 participantes do Bolão serão pontuados')
  end
end
