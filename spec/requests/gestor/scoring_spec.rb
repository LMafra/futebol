require 'rails_helper'

RSpec.describe 'Gestor match page (lances, finalizar e reverter)', type: :request do
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
  let!(:striker) { create(:player, team: own_match.home_team, position: 'ATA', name: 'Atacante Casa') }
  let!(:rival) { create(:player, team: own_match.away_team, position: 'ATA', name: 'Atacante Fora') }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
    sign_in(manager)
  end

  def record(match, player, stat = 'goals')
    post "/gestor/matches/#{match.id}/record_event",
         params: { modal: 'lance', return_to: "/gestor/matches/#{match.id}",
                   lance: { player_id: player.id, stat:, period: 'first_half', minute: '10' } }
  end

  it 'gestor abre a página da própria partida ao vivo com os lances' do
    get "/gestor/matches/#{own_match.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Casa Gestor', 'Atacante Casa', 'Registrar lance')
  end

  it 'recusa partida de campeonato de outro gestor' do
    get "/gestor/matches/#{foreign_match.id}"

    expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
  end

  it 'registra lance na própria partida' do
    record(own_match, striker)

    expect(response).to redirect_to("/gestor/matches/#{own_match.id}")
    expect(own_match.reload).to have_attributes(home_score: 1, away_score: 0)
  end

  it 'não registra lance em partida de outro gestor' do
    foreign_player = create(:player, team: foreign_match.home_team)

    record(foreign_match, foreign_player)

    expect(response.status).to be_in([403, 404])
    expect(Cartola::ScoutEvent.count).to eq(0)
  end

  it 'finaliza a própria partida após os lances e enfileira a pontuação' do
    2.times { record(own_match, striker) }
    record(own_match, rival)

    expect do
      post "/gestor/matches/#{own_match.id}/finalize",
           params: { modal: 'finalize', return_to: "/gestor/matches/#{own_match.id}",
                     finalize: { score_confirmation: '2x1' } }
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

  it 'gestor pendente não registra lance' do
    sign_in(create(:user, :pending_manager))

    record(own_match, striker)

    expect(response).to have_http_status(:forbidden)
    expect(Cartola::ScoutEvent.count).to eq(0)
  end

  it 'admin pode registrar lance pelo /gestor' do
    sign_in(create(:user, :admin))

    record(own_match, striker)

    expect(response).to redirect_to("/gestor/matches/#{own_match.id}")
  end

  it '/gestor/matchscouts e /gestor/matchfinalizer redirecionam para a partida' do
    get '/gestor/matchscouts', params: { match_id: own_match.id }
    expect(response).to redirect_to("/gestor/matches/#{own_match.id}")

    get '/gestor/matchfinalizer', params: { match_id: own_match.id }
    expect(response).to redirect_to("/gestor/matches/#{own_match.id}?modal=finalize")

    get '/gestor/matchscouts'
    expect(response).to redirect_to('/gestor/matches')
  end
end
