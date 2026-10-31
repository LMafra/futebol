require 'rails_helper'

RSpec.describe Core::Player do
  it 'is valid with team, name, position and external_id' do
    expect(build(:player)).to be_valid
  end

  it 'requires a team' do
    expect(build(:player, team: nil)).not_to be_valid
  end

  it 'only accepts Cartola positions' do
    expect(build(:player, position: 'TEC')).not_to be_valid
    Core::Player::POSITIONS.each { |position| expect(build(:player, position:)).to be_valid }
  end

  it 'keeps shirt numbers between 1 and 99' do
    expect(build(:player, shirt_number: 0)).not_to be_valid
    expect(build(:player, shirt_number: 100)).not_to be_valid
    expect(build(:player, shirt_number: nil)).to be_valid
  end

  it 'does not repeat a shirt number within the same team' do
    existing = create(:player, shirt_number: 10)

    expect(build(:player, team: existing.team, shirt_number: 10)).not_to be_valid
    expect(build(:player, shirt_number: 10)).to be_valid
  end

  it 'blocks unknown positions at the database level' do
    player = create(:player)

    expect { player.update_columns(position: 'TEC') }
      .to raise_error(ActiveRecord::StatementInvalid, /players_position_valid/)
  end
end
