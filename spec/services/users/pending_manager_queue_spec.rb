require 'rails_helper'

RSpec.describe Users::PendingManagerQueue do
  def request_at(user, time)
    create(:audit_log, action: 'user.manager_requested', user:, auditable: user, created_at: time)
  end

  it 'lists pending requests oldest first, flagging those waiting more than 24h' do
    recent = create(:user, :pending_manager, name: 'Recente')
    old = create(:user, :pending_manager, name: 'Antigo')
    create(:user, :pending_manager, name: 'Sem log', updated_at: 3.hours.ago)
    create(:user, manager_status: :approved)
    request_at(recent, 2.hours.ago)
    request_at(old, 2.days.ago)

    entries = described_class.call

    expect(entries.map { _1.user.name }).to eq(['Antigo', 'Sem log', 'Recente'])
    expect(entries.map(&:overdue?)).to eq([true, false, false])
  end

  it 'uses the latest request when a user asked more than once' do
    user = create(:user, :pending_manager)
    request_at(user, 3.days.ago)
    request_at(user, 1.hour.ago)

    expect(described_class.call.first.requested_at).to be_within(1.second).of(1.hour.ago)
  end

  it 'returns an empty queue without pending requests' do
    expect(described_class.call).to eq([])
  end
end
