require 'rails_helper'

RSpec.describe 'Gestor MatchScouts page', type: :request do
  include ActiveJob::TestHelper

  let(:manager) { create(:user, :manager) }
  let(:other_manager) { create(:user, :manager) }
  let(:own_championship) { create(:championship, manager:, name: 'Liga do Gestor') }
  let(:foreign_championship) { create(:championship, manager: other_manager, name: 'Liga Alheia') }
  let(:own_match) do
    create(:match, championship: own_championship, status: 'live', match_date: 1.hour.ago,
                   home_team: create(:team, name: 'Casa Gestor'),
                   away_team: create(:team, name: 'Fora Gestor'))
  end
  let(:foreign_match) do
    create(:match, championship: foreign_championship, status: 'live', match_date: 1.hour.ago,
                   home_team: create(:team, name: 'Casa Alheia'),
                   away_team: create(:team, name: 'Fora Alheia'))
  end
  let!(:keeper) { create(:player, team: own_match.home_team, position: 'GOL', name: 'Goleiro Casa') }
  let!(:striker) { create(:player, team: own_match.home_team, position: 'ATA', name: 'Atacante Casa') }
  let!(:rival) { create(:player, team: own_match.away_team, position: 'ATA', name: 'Atacante Fora') }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
    sign_in(manager)
  end

  def page_html = Nokogiri::HTML(response.body)

  def record(match:, highlight: nil, **rows)
    scouts = rows.to_h { |player, values| [player.id.to_s, { team_id: player.team_id, played: '0', **values }] }
    post '/gestor/matchscouts/record', params: { match_id: match.id, scouts:, highlight: highlight&.id.to_s }
  end

  def record_scouts_for_finalizer(home_goals:, away_goals:)
    rows = { own_match.home_team => home_goals, own_match.away_team => away_goals }.map do |team, goals|
      { player_id: create(:player, team:, position: 'ATA').id, team_id: team.id, played: true, goals: }
    end
    Cartola::RecordScoutsService.call(match: own_match, rows:, actor: manager, ip_address: '127.0.0.1')
  end

  it 'gestor abre scouts da própria partida ao vivo' do
    get '/gestor/matchscouts', params: { match_id: own_match.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Casa Gestor', 'Atacante Casa')
  end

  it 'recusa match_id de campeonato de outro gestor com 403' do
    get '/gestor/matchscouts', params: { match_id: foreign_match.id }

    expect(response).to have_http_status(:forbidden)
  end

  it 'salva scouts na própria partida' do
    record(match: own_match, striker => { played: '1', goals: '1' }, rival => { played: '1' }, highlight: striker)

    expect(response).to redirect_to("/gestor/matchscouts?match_id=#{own_match.id}")
    expect(own_match.reload).to have_attributes(home_score: 1, away_score: 0)
  end

  it 'finaliza a própria partida após os scouts e enfileira a pontuação' do
    record_scouts_for_finalizer(home_goals: 2, away_goals: 1)

    expect do
      post '/gestor/matchfinalizer/finalize',
           params: { finalization: { match_id: own_match.id, score_confirmation: '2x1' } }
    end.to have_enqueued_job(ProcessMatchPointsJob).with(own_match.id, kind_of(String))

    expect(response).to redirect_to("/gestor/matches/#{own_match.id}")
    expect(own_match.reload).to have_attributes(status: 'finished', home_score: 2, away_score: 1)
  end

  it 'reverte pontuação da própria partida pontuada' do
    scoring_token = SecureRandom.uuid
    own_match.update!(status: 'scored', home_score: 2, away_score: 1, match_date: 1.day.ago,
                      scores_calculated_at: 1.hour.ago, scoring_token:)
    create(:bolao_prediction_score, prediction: create(:bolao_prediction, match: own_match), scoring_token:)

    perform_enqueued_jobs do
      post '/gestor/matchreversal/revert',
           params: { reversal: { match_id: own_match.id, reason: 'Erro de lançamento' } }
    end

    expect(response).to redirect_to("/gestor/matches/#{own_match.id}")
    expect(own_match.reload).to be_reverted
  end

  it 'gestor pendente recebe 403 em /gestor/matchscouts' do
    sign_in(create(:user, :pending_manager))

    get '/gestor/matchscouts', params: { match_id: own_match.id }

    expect(response).to have_http_status(:forbidden)
  end

  it 'admin pode usar /gestor/matchscouts' do
    sign_in(create(:user, :admin))

    get '/gestor/matchscouts', params: { match_id: own_match.id }

    expect(response).to have_http_status(:ok)
  end

  it 'o seletor de partidas lista só campeonatos do gestor' do
    own_match
    foreign_match

    get '/gestor/matchscouts'

    expect(response).to have_http_status(:ok)
    options = page_html.css('select[name="match_id"] option').map(&:text).join(' ')
    expect(options).to include('Casa Gestor')
    expect(options).not_to include('Casa Alheia')
  end
end
