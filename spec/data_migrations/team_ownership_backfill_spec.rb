require 'rails_helper'

RSpec.describe Core::TeamOwnershipBackfill do
  let(:migration) { described_class.new }
  let(:first_manager) { create(:user, :manager) }
  let(:second_manager) { create(:user, :manager) }
  let(:first_championship) { create(:championship, manager: first_manager) }
  let(:second_championship) { create(:championship, manager: second_manager) }
  let(:admin_championship) { create(:championship) }
  let(:shared) { create(:team, short_name: 'SHA') }
  let!(:shared_player) { create(:player, team: shared, shirt_number: 10) }
  let(:rival) { create(:team) }
  let(:other_rival) { create(:team) }

  # Data as it was before ADR 0006: teams without owner or enrollments, playing for any championship.
  def play(championship, home_team, away_team)
    build(:match, championship:, home_team:, away_team:).tap { |match| match.save!(validate: false) }
  end

  before do
    2.times { play(first_championship, shared, rival) }
    play(second_championship, shared, other_rival)
  end

  it 'gives a team to the manager it plays most for and copies it, with its players, for the other one' do
    migration.up

    copy = Core::Team.find_by!(manager: second_manager, short_name: 'SHA')
    expect(shared.reload.manager).to eq(first_manager)
    expect(copy).not_to eq(shared)
    expect(copy.players.pluck(:name, :shirt_number)).to eq([[shared_player.name, 10]])
    expect(second_championship.matches.pluck(:home_team_id)).to eq([copy.id])
    expect(first_championship.matches.pluck(:home_team_id)).to all(eq(shared.id))
  end

  it 'enrolls every team in the championships it plays in' do
    migration.up

    copy = Core::Team.find_by!(manager: second_manager, short_name: 'SHA')
    expect(first_championship.teams).to contain_exactly(shared, rival)
    expect(second_championship.teams).to contain_exactly(copy, other_rival)
  end

  it "moves the second manager's scouts, values and lineups to the copied players" do
    match = second_championship.matches.first
    score = create(:cartola_player_score, match:, player: shared_player)
    value = create(:cartola_player_value, player: shared_player, championship: second_championship)
    lineup = create(:cartola_lineup, championship: second_championship, include_players: [shared_player])
    lineup_player = lineup.lineup_players.find_by!(player: shared_player)

    migration.up

    copied_player = Core::Team.find_by!(manager: second_manager, short_name: 'SHA').players.sole
    expect(score.reload).to have_attributes(player_id: copied_player.id, team_id: copied_player.team_id)
    expect(value.reload.player_id).to eq(copied_player.id)
    expect(lineup_player.reload.player_id).to eq(copied_player.id)
  end

  it 'keeps teams of championships without a manager, and teams without matches, with the admin' do
    play(admin_championship, rival, other_rival)
    idle = create(:team)

    migration.up

    expect(Core::Team.find_by!(manager: nil, short_name: rival.short_name)).not_to eq(rival)
    expect(idle.reload.manager).to be_nil
  end

  it 'merges the copies back on down' do
    match = second_championship.matches.first
    score = create(:cartola_player_score, match:, player: shared_player)
    migration.up

    migration.down

    expect(Core::Team.where(short_name: 'SHA')).to contain_exactly(shared)
    expect(second_championship.matches.pluck(:home_team_id)).to eq([shared.id])
    expect(score.reload).to have_attributes(player_id: shared_player.id, team_id: shared.id)
    expect(Core::ChampionshipTeam.count).to eq(0)
    expect(Core::Team.where.not(manager_id: nil)).to be_empty
  end
end
