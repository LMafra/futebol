require 'rails_helper'

RSpec.describe Simulador::StandingsCalculator do
  let(:teams) { { 1 => 'Atlético', 2 => 'Botafogo', 3 => 'Cruzeiro', 4 => 'Fortaleza' } }

  def game(id, home, away, home_score = nil, away_score = nil)
    described_class::Fixture.new(id:, home_team_id: home, away_team_id: away, home_score:, away_score:)
  end

  def table(matches, overrides = {})
    described_class.call(matches:, teams:, overrides:).map do |row|
      [row.position, row.team_name, row.points, row.played, row.wins, row.goal_difference, row.goals_for]
    end
  end

  it 'builds the table from real scores, leaving matches without a score out' do
    matches = [game(1, 1, 2, 2, 0),
               game(2, 3, 4, 1, 1),
               game(3, 1, 3)]

    expect(table(matches)).to eq([[1, 'Atlético', 3, 1, 1, 2, 2], [2, 'Cruzeiro', 1, 1, 0, 0, 1],
                                  [3, 'Fortaleza', 1, 1, 0, 0, 1], [4, 'Botafogo', 0, 1, 0, -2, 0]])
  end

  it 'projects with the overrides, which replace the score of their match' do
    matches = [game(1, 1, 2, 1, 0),
               game(2, 2, 3),
               game(3, 4, 1)]

    projected = table(matches, { 2 => { home: 3, away: 0 }, 3 => { home: 2, away: 0 } })

    expect(table(matches).first(2).map { |row| row[1] }).to eq(%w[Atlético Cruzeiro])
    expect(projected.map { |row| row.first(4) })
      .to eq([[1, 'Botafogo', 3, 2], [2, 'Fortaleza', 3, 1], [3, 'Atlético', 3, 2], [4, 'Cruzeiro', 0, 1]])
  end

  it 'breaks ties by wins, then goal difference, then goals for, then team name' do
    more_wins = [game(1, 4, 3, 1, 0),
                 game(2, 4, 1, 0, 3),
                 game(3, 4, 3, 0, 3),
                 game(4, 2, 1, 1, 1),
                 game(5, 2, 3, 2, 2),
                 game(6, 2, 3, 0, 0)]
    goals_for = [game(1, 1, 2, 3, 1),
                 game(2, 3, 4, 4, 2),
                 game(3, 2, 4, 0, 0)]
    names = [game(1, 3, 4, 1, 0),
             game(2, 1, 2, 1, 0)]

    # Fortaleza (3 pts, 1 win, -5) above Botafogo (3 pts, 3 draws, 0)
    standings = table(more_wins).map { |row| row[1] }
    expect(standings.index('Fortaleza')).to be < standings.index('Botafogo')
    expect(table(goals_for).map { |row| row[1] }).to eq(%w[Cruzeiro Atlético Fortaleza Botafogo])
    expect(table(names).map { |row| row[1] }).to eq(%w[Atlético Cruzeiro Botafogo Fortaleza])
  end

  it 'runs without the database' do
    matches = [game(1, 1, 2, 1, 0)]
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] }

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { table(matches, { 1 => { home: 0, away: 2 } }) }

    expect(queries).to be_empty
  end
end
