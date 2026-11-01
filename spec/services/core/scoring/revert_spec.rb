require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe RevertMatchPointsService do
  let(:admin) { create(:user, :admin) }
  let(:ip_address) { '203.0.113.7' }
  let(:scoring_token) { SecureRandom.uuid }
  let(:match) do
    create(:match, status: 'finished', home_score: 2, away_score: 1, match_date: 1.day.ago,
                   scores_calculated_at: 1.hour.ago, scoring_token:)
  end
  let!(:scores) do
    create_list(:bolao_prediction, 3, match:).map do |prediction|
      create(:bolao_prediction_score, prediction:, scoring_token:)
    end
  end
  let!(:other_match_score) { create(:bolao_prediction_score) }

  def revert(**overrides) = described_class.call(match:, actor: admin, ip_address:, **overrides)

  describe 'happy path' do
    it 'finished → reverted, descartando (soft delete) os scores do scoring_token' do
      expect { revert }.to change { match.reload.status }.from('finished').to('reverted')

      expect(scores.map { |score| score.reload.discarded? }).to all(be(true))
      expect(Bolao::PredictionScore.kept.where(scoring_token:)).to be_empty
      expect(Bolao::PredictionScore.with_discarded.where(scoring_token:).count).to eq(3)
      expect(other_match_score.reload).to be_kept
      expect(match).to have_attributes(scores_calculated_at: nil, scoring_token: nil)
    end

    it 'também reverte uma partida scored' do
      match.update!(status: 'scored')

      expect { revert }.to change { match.reload.status }.from('scored').to('reverted')
    end
  end

  describe 'guard' do
    it 'chama revert_match! com scores_calculated_at ainda presente (zera depois, no mesmo save)' do
      calculated_at_on_revert = nil
      allow(match).to receive(:revert_match!).and_wrap_original do |original, *args|
        calculated_at_on_revert = match.scores_calculated_at
        original.call(*args)
      end

      revert

      expect(calculated_at_on_revert).to be_present
      expect(match.reload.scores_calculated_at).to be_nil
    end

    it 'scores_calculated_at nil → AASM::InvalidTransition e nada muda' do
      match.update!(scores_calculated_at: nil)

      expect { revert }.to raise_error(AASM::InvalidTransition)
        .and(not_change { Bolao::PredictionScore.kept.count })
        .and(not_change(Core::AuditLog, :count))
      expect(match.reload).to be_finished
    end
  end

  describe 'AuditLog' do
    it 'cria 1 AuditLog revert com ip_address preenchido, ator e tokens' do
      token = SecureRandom.uuid

      expect { revert(reversal_token: token) }.to change(Core::AuditLog, :count).by(1)

      log = Core::AuditLog.last
      expect(log).to have_attributes(action: 'revert', user: admin, auditable: match)
      expect(log.ip_address.to_s).to eq(ip_address)
      expect(log.metadata).to eq('scoring_token' => scoring_token, 'reversal_token' => token, 'discarded_scores' => 3)
    end

    it 'guarda o motivo da reversão quando informado' do
      revert(reason: 'súmula corrigida')

      expect(Core::AuditLog.last.metadata).to include('reason' => 'súmula corrigida')
    end

    it 'sem ip_address → falha e faz rollback (scores continuam kept, partida intacta)' do
      expect { revert(ip_address: nil) }.to raise_error(ActiveRecord::RecordInvalid, /Ip address/)

      expect(scores.map { |score| score.reload.kept? }).to all(be(true))
      expect(match.reload).to have_attributes(status: 'finished', scoring_token:)
    end
  end

  describe 'idempotência por reversal_token' do
    it 'mesmo token 2x → a segunda execução é no-op' do
      token = SecureRandom.uuid

      expect(revert(reversal_token: token)).to be(true)
      expect { expect(revert(reversal_token: token)).to be(false) }.not_to(change { match.reload.attributes })
      expect(Core::AuditLog.where(action: 'revert').count).to eq(1)
    end
  end
end

RSpec.describe RevertMatchPointsJob do
  let(:admin) { create(:user, :admin) }
  let(:ip_address) { '198.51.100.23' }
  let(:pool) { create(:bolao_pool) }
  let(:match) { create(:match, status: 'finished', home_score: 2, away_score: 1, match_date: 1.day.ago) }
  let!(:predictions) { create_list(:bolao_prediction, 2, pool:, match:, home_guess: 2, away_guess: 1) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, kind: 'exact_score', points: 10)
    allow(Sentry).to receive(:capture_exception)
  end

  def score!(token = SecureRandom.uuid) = ProcessMatchPointsJob.perform_now(match.id, token)

  def revert!(token) = described_class.perform_now(match.id, token, ip_address:, actor_id: admin.id)

  it 'reverte a pontuação feita pelo ProcessMatchPointsJob e audita com o ip_address' do
    score!

    expect { revert!(SecureRandom.uuid) }.to change { Bolao::PredictionScore.kept.count }.from(2).to(0)
    expect(match.reload).to be_reverted
    expect(Core::AuditLog.last.ip_address.to_s).to eq(ip_address)
  end

  it 'mesmo token 2x → segunda execução é no-op (não chama o service)' do
    score!
    token = SecureRandom.uuid
    revert!(token)
    allow(RevertMatchPointsService).to receive(:call).and_call_original

    expect { revert!(token) }.not_to(change { match.reload.attributes })
    expect(RevertMatchPointsService).not_to have_received(:call)
  end

  describe 'token antigo após re_finish (re-pontuação a partir de reverted)' do
    let(:old_token) { SecureRandom.uuid }

    before do
      score!
      revert!(old_token)
      score!
    end

    it 'não re-reverte: os novos scores continuam kept e a partida segue scored' do
      expect { revert!(old_token) }.not_to(change { Bolao::PredictionScore.kept.count })
      expect(match.reload).to be_scored
    end

    it 'não re-reverte mesmo depois de outra reversão ter trocado o reversal_token' do
      revert!(SecureRandom.uuid)
      score!

      expect { revert!(old_token) }.not_to(change { Bolao::PredictionScore.kept.count })
      expect(match.reload).to be_scored
      expect(Core::AuditLog.where(action: 'revert').count).to eq(2)
    end
  end

  it 'falha → log + Sentry + re-raise' do
    allow(Rails.logger).to receive(:error).and_call_original
    token = SecureRandom.uuid

    expect { revert!(token) }.to raise_error(AASM::InvalidTransition)

    expect(Rails.logger).to have_received(:error).with(/RevertMatchPointsJob failed match_id=#{match.id}/)
    expect(Sentry).to have_received(:capture_exception)
      .with(an_instance_of(AASM::InvalidTransition),
            hash_including(extra: { match_id: match.id, reversal_token: token }))
  end
end
