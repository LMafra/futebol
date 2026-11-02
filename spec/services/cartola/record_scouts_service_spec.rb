require 'rails_helper'

RSpec.describe Cartola::RecordScoutsService do
  let(:admin) { create(:user, :admin) }
  let(:home) { create(:team) }
  let(:away) { create(:team) }
  let(:match) { create(:match, home_team: home, away_team: away, status: 'live', match_date: 1.hour.ago) }
  let(:keeper) { create(:player, team: home, position: 'GOL') }
  let(:striker) { create(:player, team: home, position: 'ATA') }
  let(:winger) { create(:player, team: home, position: 'MEI') }
  let(:rival_keeper) { create(:player, team: away, position: 'GOL') }
  let(:rival) { create(:player, team: away, position: 'ATA') }
  let!(:rule) do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, assist_points: 5,
                                  clean_sheet_points: 5, penalty_save_points: 7, save_points: 1,
                                  yellow_card_penalty: 1, red_card_penalty: 3, own_goal_penalty: 3,
                                  played_points: 1, highlight_points: 5)
  end

  def row(player, team: player.team, **scouts) = { player_id: player.id, team_id: team.id, **scouts }

  def record(*rows, on: match) = described_class.call(match: on, rows:, actor: admin, ip_address: '203.0.113.9')

  def kept = Cartola::PlayerScore.kept.where(match:)

  it 'grava só quem jogou ou tem scout, com SG e pontos derivados' do
    result = record(row(keeper, played: '1', saves: '3'), row(striker, played: '1', goals: '1'),
                    row(winger, played: '0'), row(rival, assists: '0', played: '1'), row(rival_keeper))

    expect(result).to be_success
    expect(kept.pluck(:player_id)).to contain_exactly(keeper.id, striker.id, rival.id)
    scores = kept.index_by(&:player_id)
    expect(scores[keeper.id]).to have_attributes(clean_sheet: true, saves: 3, points: 1 + 5 + 3)
    expect(scores[striker.id]).to have_attributes(clean_sheet: true, goals: 1, points: 1 + 8 + 5)
    expect(scores[rival.id]).to have_attributes(clean_sheet: false, points: 1, team_id: away.id)
  end

  it 'conta scouts sem "Jogou" e "Jogou" sem scouts, de forma independente' do
    record(row(striker, goals: '1'), row(winger, played: '1'))

    expect(kept.find_by(player: striker)).to have_attributes(played: false, clean_sheet: false, points: 8)
    expect(kept.find_by(player: winger)).to have_attributes(played: true, points: 1 + 5)
  end

  it 'descarta a linha de quem deixou de participar' do
    record(row(striker, played: '1', goals: '1'), row(winger, played: '1'))
    record(row(striker, played: '1', goals: '1'), row(winger, played: '0'))

    expect(kept.pluck(:player_id)).to eq([striker.id])
    expect(Cartola::PlayerScore.discarded.where(player: winger, match:)).to exist
  end

  it 'deriva o placar com gols contra e atualiza o placar ao vivo com broadcast' do
    allow(BroadcastUpdateService).to receive(:call)

    record(row(striker, played: '1', goals: '2'), row(rival, played: '1', goals: '1'),
           row(winger, played: '1', own_goals: '1'))

    expect(match.reload).to have_attributes(home_score: 2, away_score: 2)
    expect(Cartola::PlayerScore.score_for(match)).to eq([2, 2])
    expect(BroadcastUpdateService).to have_received(:call).with(match:)
  end

  it 'perde o SG pelo gol contra do próprio time' do
    record(row(keeper, played: '1'), row(winger, played: '1', own_goals: '1'), row(rival, played: '1'))

    expect(kept.find_by(player: keeper).clean_sheet).to be(false)
    expect(kept.find_by(player: rival).clean_sheet).to be(true)
    expect(kept.find_by(player: winger).points).to eq(1 - 3)
  end

  it 'permite pontuação negativa' do
    record(row(striker, played: '1', yellow_cards: '1', red_cards: '1', own_goals: '1'))

    expect(kept.find_by(player: striker).points).to eq(1 - 1 - 3 - 3)
  end

  it 'marca um destaque e troca o destaque sem violar o índice único' do
    record(row(striker, played: '1', highlight: true), row(winger, played: '1'))
    record(row(striker, played: '1'), row(winger, played: '1', highlight: true))

    expect(kept.where(highlight: true).pluck(:player_id)).to eq([winger.id])
    expect(kept.find_by(player: winger).points).to eq(1 + 5 + 5)
  end

  it 'registra AuditLog com placar e IP' do
    expect { record(row(striker, played: '1', goals: '1')) }
      .to change(Core::AuditLog.where(action: 'cartola.scouts_recorded'), :count).by(1)

    log = Core::AuditLog.last
    expect([log.user, log.auditable, log.ip_address.to_s]).to eq([admin, match, '203.0.113.9'])
    expect(log.metadata).to include('home_score' => 1, 'away_score' => 0, 'participants' => 1)
  end

  describe 'travas' do
    def expect_rejected(result, message)
      expect(result).not_to be_success
      expect(result.errors).to include(a_string_including(message))
      expect(kept).to be_empty
    end

    it 'recusa valores fora dos limites' do
      expect_rejected(record(row(striker, yellow_cards: '3')), 'cartões amarelos (CA) deve ficar entre 0 e 2')
      expect_rejected(record(row(keeper, penalty_saves: '4')), 'defesas de pênalti (DP) deve ficar entre 0 e 3')
      expect_rejected(record(row(striker, red_cards: '2')), 'cartões vermelhos (CV) deve ficar entre 0 e 1')
      expect_rejected(record(row(striker, goals: '-1')), 'gols (G) deve ficar entre 0 e 20')
      expect_rejected(record(row(striker, goals: 'x')), 'gols (G) deve ficar entre 0 e 20')
    end

    it 'recusa defesas (DE) de quem não é goleiro' do
      expect_rejected(record(row(striker, saves: '1')), 'defesas (DE) só contam para goleiros')
    end

    it 'recusa mais assistências que gols no time' do
      expect_rejected(record(row(striker, goals: '1'), row(winger, assists: '2')), '2 assistência(s) para 1 gol(s)')
    end

    it 'recusa assistência e gol contra na mesma linha' do
      expect_rejected(record(row(striker, goals: '1'), row(winger, assists: '1', own_goals: '1')),
                      'assistência e gol contra na mesma linha')
    end

    it 'recusa mais de um destaque' do
      expect_rejected(record(row(striker, played: '1', highlight: true), row(winger, played: '1', highlight: true)),
                      'no máximo um destaque')
    end

    it 'recusa time que não está na partida' do
      expect_rejected(record(row(striker, team: create(:team), played: '1')), 'o time não está nesta partida')
    end

    it 'recusa partida pontuada e partida que ainda não começou' do
      match.update_columns(status: 'scored', home_score: 0, away_score: 0, scores_calculated_at: Time.current)
      expect_rejected(record(row(striker, played: '1')), 'reverta a pontuação')

      match.update_columns(status: 'scheduled', match_date: 1.day.from_now, home_score: nil, away_score: nil,
                           scores_calculated_at: nil)
      expect_rejected(record(row(striker, played: '1')), 'ainda não começou')
    end
  end

  it 'inicia a partida agendada cujo horário já passou' do
    match.update_columns(status: 'scheduled', match_date: 10.minutes.ago)

    expect(record(row(striker, played: '1', goals: '1'))).to be_success
    expect(match.reload).to have_attributes(status: 'live', home_score: 1, away_score: 0)
  end

  it 'recalcula SG e pontos com a regra em vigor (finalização)' do
    record(row(striker, played: '1', goals: '1'))
    rule.update!(goal_points: 10)

    described_class.rescore!(match)

    expect(kept.find_by(player: striker).points).to eq(1 + 10 + 5)
  end
end
