require 'rails_helper'

RSpec.describe 'Lances: Scouts::RecordEvent and Scouts::UndoLast (TICKET-0096)' do
  let(:admin) { create(:user, :admin) }
  let(:home) { create(:team) }
  let(:away) { create(:team) }
  let(:match) { create(:match, home_team: home, away_team: away, status: 'live', match_date: 1.hour.ago) }
  let(:striker) { create(:player, team: home, position: 'ATA') }
  let(:winger) { create(:player, team: home, position: 'MEI') }
  let(:rival_keeper) { create(:player, team: away, position: 'GOL') }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, assist_points: 5,
                                  clean_sheet_points: 5, save_points: 1, played_points: 1, yellow_card_penalty: 1,
                                  red_card_penalty: 3)
  end

  def record(player, stat, on: match, **attributes)
    event = Cartola::ScoutEvent.new(match: on, player:, stat:, **attributes)
    Scouts::RecordEvent.call(event:, actor: admin, ip_address: '203.0.113.9')
  end

  def undo(player, stat) = Scouts::UndoLast.call(match:, player:, stat:, actor: admin, ip_address: '203.0.113.9')

  def score_of(player) = Cartola::PlayerScore.kept.find_by(match:, player:)

  it 'records a goal with period and minute and recounts the scouts and the score' do
    record(rival_keeper, 'saves')
    result = record(striker, 'goals', period: 'first_half', minute: 32)

    expect(result).to be_success
    expect(result.event).to have_attributes(team_id: home.id, recorded_by: admin, minute: 32, period_label: '1º tempo')
    expect(score_of(striker)).to have_attributes(goals: 1, played: true, clean_sheet: true, points: 1 + 8 + 5)
    expect(score_of(rival_keeper)).to have_attributes(saves: 1, clean_sheet: false, points: 1 + 1)
    expect(match.reload).to have_attributes(home_score: 1, away_score: 0)
    expect(Core::AuditLog.last).to have_attributes(action: 'cartola.scout_event_recorded', auditable: match)
  end

  it 'undoes the last lance of that player and stat, keeping it discarded' do
    first = record(striker, 'goals', period: 'first_half', minute: 10).event
    last = record(striker, 'goals', period: 'second_half', minute: 5).event

    result = undo(striker, 'goals')

    expect(result).to be_success
    expect(last.reload).to be_discarded
    expect(first.reload).not_to be_discarded
    expect(score_of(striker).goals).to eq(1)
    expect(match.reload.home_score).to eq(1)
    expect(Core::AuditLog.last.action).to eq('cartola.scout_event_undone')
  end

  it 'refuses what the scout sheet refuses' do
    expect(record(winger, 'saves').errors).to eq(['Defesas (DE) só contam para goleiros.'])
    expect(record(winger, 'assists').errors.first).to start_with('Lance o gol antes da assistência')
    record(winger, 'red_cards')
    expect(record(winger, 'red_cards').errors.first).to include('já tem o máximo de cartões vermelhos (CV) (1)')
    expect(record(create(:player), 'goals').errors).to eq(['O time do jogador não está nesta partida.'])
    expect(record(striker, 'goals', minute: 200).errors).to be_present
  end

  it 'keeps assists within the goals when undoing a goal' do
    record(striker, 'goals')
    record(winger, 'assists')

    expect(undo(striker, 'goals').errors.first).to start_with('Desfaça antes uma assistência')
    expect(undo(winger, 'assists')).to be_success
    expect(undo(striker, 'goals')).to be_success
    expect(undo(striker, 'goals').errors).to eq(['Nada para desfazer.'])
  end

  it 'starts a scheduled match whose kickoff has passed and refuses a scored one' do
    scheduled = create(:match, home_team: home, away_team: away, status: 'scheduled', match_date: 5.minutes.ago)
    expect(record(striker, 'goals', on: scheduled)).to be_success
    expect(scheduled.reload).to be_live

    scheduled.update_columns(status: 'scored', scores_calculated_at: Time.current)
    expect(record(striker, 'goals', on: scheduled).errors.first).to start_with('A partida já foi pontuada')
  end
end
