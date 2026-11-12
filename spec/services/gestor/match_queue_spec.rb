require 'rails_helper'

RSpec.describe Gestor::MatchQueue do
  let(:championship) { create(:championship) }
  let(:now) { Time.zone.parse('2026-11-12 15:00') }

  def match(status, at, **attrs) = create(:match, championship:, status:, match_date: at, **attrs)

  def queue = described_class.call(Core::Match.where(championship:), now:)

  def scout(game) = create(:cartola_player_score, match: game, player: create(:player, team: game.home_team))

  it 'gives every state its single next step, open matches by kickoff and then the latest scored' do
    future = match('scheduled', now + 1.day)
    overdue = match('scheduled', now - 1.hour)
    live_scouted = match('live', now - 3.hours).tap { scout(_1) }
    live_empty = match('live', now - 2.hours)
    finished = match('finished', now - 5.hours, home_score: 1, away_score: 0)
    scored = match('scored', now - 1.day, home_score: 2, away_score: 2, scores_calculated_at: now - 20.hours)

    steps = queue.items.to_h { |item| [item.match, item.step] }

    expect(steps).to eq(finished => :scoring, live_scouted => :finalize, live_empty => :scouts, overdue => :scouts,
                        future => :edit, scored => :scored)
    expect(steps.keys.last).to eq(scored)
  end

  it 'counts today, matches waiting for scouts and matches ready to finalize' do
    match('scheduled', now + 2.hours)
    match('scheduled', now - 1.hour)
    match('live', now - 2.hours).tap { scout(_1) }
    match('live', now - 26.hours)

    expect(queue.kpis).to eq(today: 3, awaiting_scouts: 2, awaiting_finalization: 1)
  end

  it 'ignores discarded scouts' do
    game = match('live', now - 1.hour)
    scout(game).discard

    expect(queue.step_for(game)).to eq(:scouts)
  end
end
