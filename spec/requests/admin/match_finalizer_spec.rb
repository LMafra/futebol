require 'rails_helper'

RSpec.describe 'Admin MatchFinalizer page', type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 2.hours.ago) }

  before { sign_in(admin) }

  def finalize(**fields)
    post '/admin/matchfinalizer/finalize', params: { finalization: { match_id: match.id, **fields } }
  end

  it 'mostra o formulário com o placar pré-preenchido vindo do preview' do
    get '/admin/matchfinalizer', params: { match_id: match.id, home_score: 2, away_score: 1 }

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('input[name="finalization[home_score]"]')['value']).to eq('2')
    expect(page.at_css('input[name="finalization[score_confirmation]"]')).to be_present
  end

  describe 'finalização exige confirmação com placar' do
    it 'sem confirmação → 422 com erro e partida intacta' do
      expect { finalize(home_score: 2, away_score: 1, score_confirmation: '') }
        .not_to(change { match.reload.attributes })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Confirmação do placar é obrigatória')
      expect(enqueued_jobs).to be_empty
    end

    it 'confirmação diferente do placar → 422' do
      finalize(home_score: 2, away_score: 1, score_confirmation: '1x2')

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('não confere com o placar informado (digite 2x1)')
      expect(match.reload).to be_live
    end

    it 'confirmação igual ao placar → finaliza, audita e enfileira a pontuação' do
      expect { finalize(home_score: 2, away_score: 1, score_confirmation: '2 x 1') }
        .to have_enqueued_job(ProcessMatchPointsJob).with(match.id, kind_of(String))
        .and change(Core::AuditLog.where(action: 'finalize'), :count).by(1)

      expect(response).to redirect_to("/admin/matches/#{match.id}")
      expect(match.reload).to have_attributes(status: 'finished', home_score: 2, away_score: 1)
      expect(Core::AuditLog.last).to have_attributes(user: admin, ip_address: IPAddr.new('127.0.0.1'))
    end
  end

  it 'rejeita partida que ainda não começou' do
    match.update!(status: 'scheduled', match_date: 1.day.from_now)

    finalize(home_score: 1, away_score: 0, score_confirmation: '1x0')

    expect(response).to have_http_status(:unprocessable_content)
    expect(match.reload).to be_scheduled
  end

  it 'não-admin recebe 403 e não finaliza' do
    sign_in(create(:user))

    finalize(home_score: 2, away_score: 1, score_confirmation: '2x1')

    expect(response).to have_http_status(:forbidden)
    expect(match.reload).to be_live
  end
end
