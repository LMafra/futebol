require 'rails_helper'

RSpec.describe Core::PointDeduction do
  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match) }
  let(:championship) { match.championship }

  def deduction(**attributes)
    described_class.new(championship:, team: match.home_team, points: 3, reason: 'W.O. na 2ª rodada',
                        created_by: admin, **attributes)
  end

  it 'needs positive whole points, a reason and an author' do
    expect(deduction).to be_valid
    invalid = deduction(points: 0, reason: ' ', created_by: nil)

    expect(invalid).not_to be_valid
    expect(invalid.errors.attribute_names).to include(:points, :reason, :created_by)
    expect(deduction(points: 1.5)).not_to be_valid
  end

  it 'only takes a team enrolled in the championship' do
    outsider = deduction(team: create(:team))

    expect(outsider).not_to be_valid
    expect(outsider.errors[:team_id]).to include('não está inscrito neste campeonato')
  end

  it 'is revoked without being deleted' do
    record = deduction.tap(&:save!)

    record.revoke!(admin)

    expect(described_class.active).to be_empty
    expect(record.reload).to have_attributes(revoked?: true, revoked_by: admin)
    expect(described_class.count).to eq(1)
  end

  it 'is enforced by the database too' do
    record = deduction.tap(&:save!)

    expect { record.update_columns(points: 0) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
