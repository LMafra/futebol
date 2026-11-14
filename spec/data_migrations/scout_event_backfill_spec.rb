require 'rails_helper'

RSpec.describe Cartola::ScoutEventBackfill do
  let(:migration) { described_class.new(ActiveRecord::Base.connection) }
  let(:match) { create(:match) }
  let(:player) { create(:player, team: match.home_team) }
  let!(:score) do
    Cartola::PlayerScore.create!(match:, player:, team: match.home_team, goals: 2, yellow_cards: 1, played: true,
                                 points: 12.5)
  end

  it 'creates one lance without period or minute per unit of each kept counter' do
    Cartola::PlayerScore.create!(match:, player: create(:player, team: match.away_team), team: match.away_team,
                                 goals: 3, points: 0, discarded_at: Time.current)

    migration.up

    events = Cartola::ScoutEvent.where(match:)
    expect(events.group(:stat).count).to eq('goals' => 2, 'yellow_cards' => 1)
    expect(events.pluck(:player_id, :team_id, :period, :minute).uniq).to eq([[player.id, match.home_team_id, nil, nil]])
    expect(score.reload.points).to eq(12.5)
  end

  it 'adds nothing when run again and removes only the backfilled lances on down' do
    migration.up
    migration.up
    expect(Cartola::ScoutEvent.count).to eq(3)

    Cartola::ScoutEvent.create!(match:, player:, team: match.home_team, stat: 'assists', minute: 40,
                                period: 'second_half')
    migration.down
    expect(Cartola::ScoutEvent.pluck(:stat)).to eq(['assists'])
  end
end
