require 'rails_helper'

RSpec.describe 'Admin MatchFinalizer page', type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 2.hours.ago) }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME)
    sign_in(admin)
  end

  def record_scouts(home_goals:, away_goals:)
    rows = { match.home_team => home_goals, match.away_team => away_goals }.map do |team, goals|
      { player_id: create(:player, team:, position: 'ATA').id, team_id: team.id, played: true, goals: }
    end
    Cartola::RecordScoutsService.call(match:, rows:, actor: admin, ip_address: '127.0.0.1')
  end

  def finalize(**fields)
    post '/admin/matchfinalizer/finalize', params: { finalization: { match_id: match.id, **fields } }
  end

  it 'bloqueia a finalização sem scouts, com link para a tela de scouts' do
    get '/admin/matchfinalizer', params: { match_id: match.id }

    page = Nokogiri::HTML(response.body)
    expect(page.at_css('[data-role="no-scouts"]').text).to include('Lance os scouts antes de finalizar')
    expect(page.at_css('[data-role="no-scouts"] a')['href']).to eq("/admin/matchscouts?match_id=#{match.id}")
    expect(page.at_css('input[name="finalization[score_confirmation]"]')).to be_nil

    finalize(score_confirmation: '0x0')
    expect(response).to have_http_status(:unprocessable_content)
    expect(match.reload).to be_live
  end

  it 'mostra o placar derivado dos scouts, só para leitura' do
    record_scouts(home_goals: 2, away_goals: 1)

    get '/admin/matchfinalizer', params: { match_id: match.id }

    page = Nokogiri::HTML(response.body)
    expect(page.at_css('[data-role="derived-score"]').text.squish)
      .to eq("#{match.home_team.name} 2 × 1 #{match.away_team.name}")
    expect(page.at_css('input[name="finalization[home_score]"]')).to be_nil
  end

  describe 'finalização exige confirmação do placar dos scouts' do
    before { record_scouts(home_goals: 2, away_goals: 1) }

    it 'sem confirmação → 422 com erro e partida intacta' do
      expect { finalize(score_confirmation: '') }.not_to(change { match.reload.attributes })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Confirmação do placar é obrigatória')
      expect(enqueued_jobs).to be_empty
    end

    it 'confirmação diferente do placar → 422' do
      finalize(score_confirmation: '1x2')

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('não confere com o placar dos scouts (digite 2x1)')
      expect(match.reload).to be_live
    end

    it 'ignora placar enviado no formulário e finaliza com o dos scouts' do
      expect { finalize(home_score: 5, away_score: 0, score_confirmation: '2 x 1') }
        .to have_enqueued_job(ProcessMatchPointsJob).with(match.id, kind_of(String))
        .and change(Core::AuditLog.where(action: 'finalize'), :count).by(1)

      expect(response).to redirect_to("/admin/matches/#{match.id}")
      expect(match.reload).to have_attributes(status: 'finished', home_score: 2, away_score: 1)
      expect(Core::AuditLog.last).to have_attributes(user: admin, ip_address: IPAddr.new('127.0.0.1'))
    end
  end

  it 'rejeita partida que ainda não começou' do
    match.update!(status: 'scheduled', match_date: 1.day.from_now)

    finalize(score_confirmation: '1x0')

    expect(response).to have_http_status(:unprocessable_content)
    expect(match.reload).to be_scheduled
  end

  it 'não-admin recebe 403 e não finaliza' do
    sign_in(create(:user))

    finalize(score_confirmation: '2x1')

    expect(response).to have_http_status(:forbidden)
    expect(match.reload).to be_live
  end
end
