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

  it 'repeats a short_name across managers but not within one' do
    manager = create(:user, :manager)
    create(:team, short_name: 'FLA', manager:)

    expect(build(:team, short_name: 'FLA', manager:)).not_to be_valid
    expect(build(:team, short_name: 'FLA')).to be_valid
    expect(build(:team, short_name: 'FLA', manager: create(:user, :manager))).to be_valid
  end

  it "normalizes the captain's phone to DDD and number" do
    expect(build(:team, captain_phone: '+55 (11) 98765-4321').captain_phone).to eq('11987654321')
    expect(build(:team, captain_phone: '(55) 9 9123-4567').captain_phone).to eq('55991234567')
    expect(build(:team, captain_phone: '  ').captain_phone).to be_nil
  end

  it "accepts Brazilian mobile and landline numbers for the captain's phone" do
    expect(build(:team, captain_phone: '11987654321')).to be_valid
    expect(build(:team, captain_phone: '1133334444')).to be_valid
    expect(build(:team, captain_phone: '987654321')).not_to be_valid
    expect(build(:team, captain_phone: '11187654321')).not_to be_valid
  end

  it 'keeps its manager while enrolled in a championship' do
    team = create(:match).home_team

    expect(team.update(manager: create(:user, :manager))).to be(false)
    expect(team.errors[:manager]).to be_present
  end
end
