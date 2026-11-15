require 'rails_helper'

RSpec.describe 'Editing a scored match: Scouts::Rescore (TICKET-0111)' do
  let(:admin) { create(:user, :admin) }
  let(:championship) { create(:championship, cartola_base_player_value: 5) }
  let(:match) { create(:match, championship:, status: 'live', match_date: 1.hour.ago) }
  let(:striker) { create(:player, team: match.home_team, position: 'ATA') }
  let(:rival) { create(:player, team: match.away_team, position: 'ATA') }
  let!(:prediction) { create(:bolao_prediction, match:, home_guess: 1, away_guess: 0) }
  let!(:first_token) do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
    record(striker, 'goals')
    FinalizeMatchService.call(match:, home_score: 1, away_score: 0, actor: admin, ip_address: '10.0.0.1')
    match.reload.scoring_token
  end

  def record(player, stat)
    Scouts::RecordEvent.call(event: Cartola::ScoutEvent.new(match:, player:, stat:), actor: admin,
                             ip_address: '10.0.0.1')
  end

  def kept_points = Bolao::PredictionScore.kept.where(prediction:).pluck(:points, :scoring_token)

  it 'records a lance on a scored match: the score follows the lances and the points are calculated again' do
    expect(record(rival, 'goals')).to be_success

    expect(match.reload).to have_attributes(status: 'scored', home_score: 1, away_score: 1)
    expect(match.scoring_token).not_to eq(first_token)
    expect(kept_points).to eq([[0, match.scoring_token]])
    expect(Bolao::PredictionScore.discarded.where(prediction:, scoring_token: first_token)).to exist
  end

  it 'audits the score before and after, with both scoring tokens' do
    record(rival, 'goals')

    log = Core::AuditLog.find_by!(action: 'rescore')
    expect(log).to have_attributes(user: admin, auditable: match)
    expect(log.metadata).to eq('home_score' => 1, 'away_score' => 1, 'scoring_token' => match.reload.scoring_token,
                               'before' => { 'home_score' => 1, 'away_score' => 0, 'scoring_token' => first_token })
  end

  it 'undoes a lance on a scored match and the points come back' do
    record(rival, 'goals')

    expect(Scouts::UndoLast.call(match:, player: rival, stat: 'goals', actor: admin, ip_address: '10.0.0.1'))
      .to be_success

    expect(match.reload).to have_attributes(status: 'scored', home_score: 1, away_score: 0)
    expect(kept_points).to eq([[10, match.scoring_token]])
  end

  it 'marks Jogou on a scored match and prices the players again under the new token only' do
    Scouts::MarkParticipation.call(match:, player: rival, flags: { played: true }, actor: admin,
                                   ip_address: '10.0.0.1')

    expect(match.reload).to be_scored
    expect(Cartola::PlayerValueHistory.where(scoring_token: first_token)).to be_empty
    expect(Cartola::PlayerValueHistory.where(scoring_token: match.scoring_token).pluck(:player_id))
      .to contain_exactly(striker.id, rival.id)
  end

  it 'leaves a match that is not scored without points' do
    match.update!(status: 'reverted', scores_calculated_at: nil, scoring_token: nil)

    record(rival, 'goals')

    expect(match.reload).to have_attributes(status: 'reverted', scoring_token: nil)
    expect(Core::AuditLog.where(action: 'rescore')).to be_empty
  end
end
