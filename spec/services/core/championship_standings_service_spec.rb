require 'rails_helper'

RSpec.describe Core::ChampionshipStandingsService do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }
  let(:teams) { %w[Atlético Botafogo Cruzeiro].map { |name| create(:team, manager:, name:) } }

  before do
    create(:match, championship:, home_team: teams[0], away_team: teams[1], status: 'finished',
                   home_score: 1, away_score: 0)
    create(:match, championship:, home_team: teams[2], away_team: teams[1], status: 'finished',
                   home_score: 0, away_score: 0)
    PointDeductions.deduct(championship:, attributes: { team_id: teams[1].id, points: 2, reason: 'W.O.' },
                           actor: manager, ip_address: '127.0.0.1')
  end

  it 'builds the full table with the active deductions' do
    table = described_class.table(championship)

    expect(table.standings.map { |row| [row.team_name, row.points, row.deduction] })
      .to eq([['Atlético', 3, 0], ['Cruzeiro', 1, 0], ['Botafogo', -1, 2]])
    expect(table.teams.map(&:name)).to eq(%w[Atlético Botafogo Cruzeiro])
  end

  it 'keeps a deducted team out of the leaders among the deducted ones on the home' do
    top = described_class.top([championship], limit: 1).fetch(championship.id)

    expect(top.leaders.map { |row| [row.name, row.points, row.detail] }).to eq([['Atlético', 3, nil]])
    expect(top.deducted.map { |row| [row.name, row.detail, row.deduction_reasons] })
      .to eq([['Botafogo', '−2', ['W.O.']]])
  end
end
