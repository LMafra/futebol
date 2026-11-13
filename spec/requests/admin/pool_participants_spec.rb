require 'rails_helper'

RSpec.describe 'Participantes › Bolão', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }
  let(:pool) { create(:bolao_pool, championship:, owner: manager) }
  let(:token) { SecureRandom.uuid }
  let(:scored) do
    create(:match, championship:, status: 'scored', home_score: 2, away_score: 1, scoring_token: token,
                   scores_calculated_at: 1.day.ago, match_date: 2.days.ago)
  end
  let(:ana) { member('Ana') }
  let(:bia) { member('Bia') }
  let(:caio) { member('Caio') }

  before { create(:bolao_scoring_rule) }

  def page = Nokogiri::HTML5(response.body)
  def member(name) = create(:user, name:).tap { pool.memberships.create!(user: _1) }

  def predict(user, home, away, points:)
    create(:bolao_prediction, pool:, user:, match: scored, home_guess: home, away_guess: away).tap do |prediction|
      create(:bolao_prediction_score, prediction:, points:, scoring_token: token)
    end
  end

  def correct(prediction, reason:, home: 2, away: 1, area: 'admin')
    post "/#{area}/pools/#{pool.id}/correct_prediction",
         params: { modal: 'correction', return_to: "/#{area}/pools/#{pool.id}?membro=#{prediction.user_id}",
                   correction: { prediction_id: prediction.id, home_guess: home, away_guess: away, reason: } }
  end

  context 'as admin' do
    before { sign_in(admin) }

    it 'mostra o ranking com empates na mesma posição e os palpites do participante escolhido' do
      predict(ana, 2, 1, points: 10)
      predict(bia, 2, 1, points: 10)
      predict(caio, 1, 0, points: 5)

      get "/admin/pools/#{pool.id}", params: { membro: caio.id }

      expect(response).to have_http_status(:ok)
      rows = page.css('[data-role="ranking-row"]').map { _1.css('td').map { |cell| cell.text.squish } }
      expect(rows).to eq([%w[1 Ana 1 10], %w[1 Bia 1 10], %w[3 Caio 1 5]])
      detail = page.at_css('[data-role="member-detail"]')
      expect(detail['data-user-id']).to eq(caio.id.to_s)
      expect(detail.css('[data-role="member-prediction"] [data-role="prediction-points"]').map(&:text)).to eq(['5 pts'])
      expect(page.at_css('dialog#modal-correction')).to be_present
    end

    it 'corrige o palpite com motivo, recalcula os pontos da partida pontuada e volta para o participante' do
      prediction = predict(caio, 1, 0, points: 5)

      expect { correct(prediction, reason: 'Digitou errado no celular') }
        .to change { Core::AuditLog.where(action: 'bolao.prediction_corrected').count }.by(1)

      expect(response).to redirect_to("/admin/pools/#{pool.id}?membro=#{caio.id}")
      expect(prediction.reload).to have_attributes(home_guess: 2, away_guess: 1)
      expect(prediction.scores.kept.sole.points).to eq(10)
      log = Core::AuditLog.find_by(action: 'bolao.prediction_corrected')
      expect(log).to have_attributes(user: admin, auditable: pool)
      expect(log.metadata).to include('reason' => 'Digitou errado no celular', 'points' => 10,
                                      'before' => { 'home_guess' => 1, 'away_guess' => 0 })
    end

    it 'sem motivo volta para o diálogo aberto, com o participante, sem alterar o palpite' do
      prediction = predict(caio, 1, 0, points: 5)

      correct(prediction, reason: '')

      expect(response).to redirect_to("/admin/pools/#{pool.id}?membro=#{caio.id}&modal=correction")
      expect(prediction.reload).to have_attributes(home_guess: 1, away_guess: 0)
      follow_redirect!
      dialog = page.at_css('dialog#modal-correction[open]')
      expect(dialog.at_css('[role="alert"]').text).to include('Motivo é obrigatório')
      expect(dialog.at_css('input[name="return_to"]')['value']).to eq("/admin/pools/#{pool.id}?membro=#{caio.id}")
    end

    it 'remove o participante com motivo: palpites e pontos saem do ranking e ficam no histórico' do
      prediction = predict(caio, 1, 0, points: 5)
      predict(ana, 2, 1, points: 10)

      post "/admin/pools/#{pool.id}/remove_member",
           params: { modal: 'removal', return_to: "/admin/pools/#{pool.id}",
                     removal: { user_id: caio.id, reason: 'Pediu para sair' } }

      expect(response).to redirect_to("/admin/pools/#{pool.id}")
      expect(pool.member?(caio)).to be(false)
      expect(prediction.reload).to be_discarded
      expect(prediction.scores.sole).to be_discarded
      expect(Core::AuditLog.find_by(action: 'bolao.member_removed').metadata)
        .to include('user_id' => caio.id, 'reason' => 'Pediu para sair', 'predictions_discarded' => 1)
      follow_redirect!
      expect(page.css('[data-role="ranking-row"]').map { _1.css('td')[1].text.squish }).to eq(['Ana'])
    end
  end

  context 'as gestor' do
    before { sign_in(manager) }

    it 'corrige palpites dos bolões dos seus campeonatos' do
      prediction = predict(caio, 1, 0, points: 5)

      get "/gestor/pools/#{pool.id}"
      expect(page.css('[data-role="ranking-row"]').size).to eq(1)

      correct(prediction, reason: 'Combinado no grupo', area: 'gestor')
      expect(prediction.reload.home_guess).to eq(2)
    end

    it 'não alcança bolões de campeonatos de outro gestor' do
      foreign = create(:bolao_pool, championship: create(:championship, manager: create(:user, :manager)))
      prediction = create(:bolao_prediction, pool: foreign, match: create(:match, championship: foreign.championship))

      post "/gestor/pools/#{foreign.id}/correct_prediction",
           params: { correction: { prediction_id: prediction.id, home_guess: 5, away_guess: 5, reason: 'x' } }

      expect(response).not_to have_http_status(:see_other)
      expect(prediction.reload.home_guess).to eq(1)
    end
  end
end
