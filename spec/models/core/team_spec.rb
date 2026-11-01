require 'rails_helper'

RSpec.describe Core::Team do
  it 'is valid with name, 3-letter short_name and external_id' do
    expect(build(:team)).to be_valid
  end

  it 'requires a name' do
    expect(build(:team, name: '')).not_to be_valid
  end

  it 'requires a 3-letter short_name and upcases it' do
    expect(build(:team, short_name: 'FLAM')).not_to be_valid
    expect(build(:team, short_name: ' fla ').short_name).to eq('FLA')
  end

  it 'enforces unique external_id' do
    create(:team, external_id: 'team-fla')

    expect(build(:team, external_id: 'team-fla')).not_to be_valid
  end

  it 'blocks short_name of the wrong length at the database level' do
    team = create(:team)

    expect { team.update_columns(short_name: 'FLAM') }
      .to raise_error(ActiveRecord::StatementInvalid, /core_teams_short_name_length/)
  end

  it 'cannot be destroyed while it has players' do
    team = create(:player).team

    expect(team.destroy).to be(false)
    expect(team.errors[:base]).to be_present
  end
end
