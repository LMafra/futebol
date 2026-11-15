require 'rails_helper'

RSpec.describe Core::ChampionshipTeam do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }

  it "enrolls a team of the championship's manager once" do
    team = create(:team, manager:)
    championship.championship_teams.create!(team:)

    expect(championship.championship_teams.build(team:)).not_to be_valid
    expect(championship.teams).to contain_exactly(team)
  end

  it 'refuses a team of another manager or of the admin' do
    expect(championship.championship_teams.build(team: create(:team, manager: create(:user, :manager)))).not_to be_valid
    expect(championship.championship_teams.build(team: create(:team))).not_to be_valid
  end

  it 'cannot be removed while the team has matches in the championship' do
    match = create(:match, championship:)
    enrollment = championship.championship_teams.find_by!(team: match.home_team)

    expect(enrollment.destroy).to be(false)
    expect(enrollment.errors[:base].sole).to include('já tem partidas')
  end
end
