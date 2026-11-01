require 'rails_helper'

RSpec.describe 'Admin MatchReversal page', type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:scoring_token) { SecureRandom.uuid }
  let(:match) do
    create(:match, status: 'scored', home_score: 2, away_score: 1, match_date: 1.day.ago,
                   scores_calculated_at: 1.hour.ago, scoring_token:)
  end
  let!(:score) { create(:bolao_prediction_score, prediction: create(:bolao_prediction, match:), scoring_token:) }

  before { sign_in(admin) }

  def revert(reason)
    post '/admin/matchreversal/revert', params: { reversal: { match_id: match.id, reason: } }
  end

  it 'mostra o formulário com o campo motivo obrigatório' do
    get '/admin/matchreversal', params: { match_id: match.id }

    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).at_css('textarea[name="reversal[reason]"]')['required']).to be_present
  end

  it 'reversão exige motivo (campo vazio → erro)' do
    perform_enqueued_jobs do
      expect { revert('   ') }.not_to change(Core::AuditLog, :count)
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Motivo é obrigatório')
    expect(match.reload).to be_scored
    expect(score.reload).to be_kept
  end

  it 'AuditLog criado após reversão (motivo, ator e IP), com os pontos descartados' do
    perform_enqueued_jobs do
      expect { revert('Placar lançado errado pela súmula') }.to change(Core::AuditLog, :count).by(1)
    end

    expect(response).to redirect_to("/admin/matches/#{match.id}")
    log = Core::AuditLog.last
    expect(log).to have_attributes(action: 'revert', user: admin, auditable: match)
    expect(log.ip_address.to_s).to eq('127.0.0.1')
    expect(log.metadata).to include('reason' => 'Placar lançado errado pela súmula', 'scoring_token' => scoring_token)
    expect(match.reload).to be_reverted
    expect(score.reload).to be_discarded
  end

  it 'partida sem pontuação → erro' do
    match.update!(status: 'reverted', scores_calculated_at: nil, scoring_token: nil)

    revert('qualquer motivo')

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('nada para reverter')
  end

  it 'não-admin recebe 403 e nada é enfileirado' do
    sign_in(create(:user))

    expect { revert('motivo') }.not_to have_enqueued_job(RevertMatchPointsJob)
    expect(response).to have_http_status(:forbidden)
  end
end
