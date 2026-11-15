require 'rails_helper'

RSpec.describe FinalizeMatchService do
  let(:admin) { create(:user, :admin) }

  def finalize(match) = described_class.call(match:, home_score: 3, away_score: 2, actor: admin, ip_address: '10.0.0.1')

  it 'finishes and scores a live match in the same request, without a queue, and audits it' do
    match = create(:match, status: 'live', match_date: 1.hour.ago)
    prediction = create(:bolao_prediction, match:, home_guess: 3, away_guess: 2)
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)

    expect { finalize(match) }.not_to have_enqueued_job

    expect(match.reload).to have_attributes(status: 'scored', home_score: 3, away_score: 2)
    expect(Bolao::PredictionScore.find_by!(prediction:))
      .to have_attributes(points: 10, scoring_token: match.scoring_token)
    expect(Core::AuditLog.last).to have_attributes(action: 'finalize', user: admin, auditable: match)
    expect(Core::AuditLog.last.metadata)
      .to eq('home_score' => 3, 'away_score' => 2, 'scoring_token' => match.scoring_token)
  end

  it 'starts, finishes and scores a scheduled match whose kickoff has passed' do
    match = create(:match, status: 'scheduled', match_date: 2.hours.ago)

    finalize(match)

    expect(match.reload).to be_scored
  end

  it 'scores a match left finished by the old queue, and a reverted one' do
    finished = create(:match, status: 'finished', home_score: 1, away_score: 0, match_date: 1.day.ago)
    reverted = create(:match, status: 'reverted', home_score: 0, away_score: 0, match_date: 1.day.ago)

    [finished, reverted].each { finalize(_1) }

    expect([finished.reload, reverted.reload].map { [_1.status, _1.home_score, _1.away_score] })
      .to eq([['scored', 3, 2], ['scored', 3, 2]])
  end

  it 'refuses a match that has not kicked off, without scoring or auditing' do
    match = create(:match, status: 'scheduled', match_date: 1.day.from_now)

    expect { finalize(match) }.to raise_error(AASM::InvalidTransition)
    expect(Core::AuditLog.count).to eq(0)
    expect(match.reload).to have_attributes(status: 'scheduled', home_score: nil)
  end
end
