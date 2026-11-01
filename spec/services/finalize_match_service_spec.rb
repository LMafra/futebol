require 'rails_helper'

RSpec.describe FinalizeMatchService do
  let(:admin) { create(:user, :admin) }

  def finalize(match) = described_class.call(match:, home_score: 3, away_score: 2, actor: admin, ip_address: '10.0.0.1')

  it 'finishes a live match with the score, audits it and enqueues the scoring' do
    match = create(:match, status: 'live', match_date: 1.hour.ago)

    expect { finalize(match) }.to have_enqueued_job(ProcessMatchPointsJob).with(match.id, kind_of(String))

    expect(match.reload).to have_attributes(status: 'finished', home_score: 3, away_score: 2)
    expect(Core::AuditLog.last).to have_attributes(action: 'finalize', user: admin, auditable: match)
    expect(Core::AuditLog.last.metadata).to eq('home_score' => 3, 'away_score' => 2)
  end

  it 'starts and finishes a scheduled match whose kickoff has passed' do
    match = create(:match, status: 'scheduled', match_date: 2.hours.ago)

    finalize(match)

    expect(match.reload).to be_finished
  end

  it 'refuses a match that has not kicked off, without enqueuing or auditing' do
    match = create(:match, status: 'scheduled', match_date: 1.day.from_now)

    expect { finalize(match) }.to raise_error(AASM::InvalidTransition)
    expect(Core::AuditLog.count).to eq(0)
    expect(match.reload).to have_attributes(status: 'scheduled', home_score: nil)
  end
end
