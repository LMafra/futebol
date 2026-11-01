require 'rails_helper'

RSpec.describe Bolao::CalculatePreviewService do
  let(:match) { create(:match, status: 'finished', home_score: 0, away_score: 0, match_date: 1.day.ago) }
  let(:pool) { create(:bolao_pool) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
  end

  def predict(home_guess, away_guess, in_pool: pool)
    create(:bolao_prediction, pool: in_pool, match:, home_guess:, away_guess:)
  end

  def preview(home = 2, away = 1) = described_class.call(match:, candidate_home: home, candidate_away: away)

  def points_for(prediction) = preview.rows.find { |row| row.prediction_id == prediction.id }.points

  context 'com o bolão configurado em 5 (exato) / 3 (tendência) / 0 (erro), candidato 2x1' do
    before { create(:bolao_scoring_rule, pool:, exact_score_points: 5, winner_points: 3) }

    it 'placar exato → 5 pts' do
      expect(points_for(predict(2, 1))).to eq(5)
    end

    it 'tendência (acertou o vencedor) → 3 pts' do
      expect(points_for(predict(3, 0))).to eq(3)
    end

    it 'empate certo com placar errado → 3 pts (mesma faixa do vencedor)' do
      expect(points_for(predict(1, 1))).to eq(0)
      expect(described_class.call(match:, candidate_home: 0, candidate_away: 0).total).to eq(3)
    end

    it 'erro → 0 pts' do
      expect(points_for(predict(0, 2))).to eq(0)
    end
  end

  it 'usa a regra do campeonato quando o bolão não tem pontuação própria' do
    create(:bolao_scoring_rule, championship: pool.championship, exact_score_points: 12, winner_points: 6)

    expect(points_for(predict(2, 1))).to eq(12)
  end

  it 'usa candidate_home/away por parâmetro, nunca o placar real da partida (0x0)' do
    exact_candidate = predict(2, 1)
    exact_real_score = predict(0, 0)
    allow(match).to receive_messages(home_score: 0, away_score: 0)

    expect(points_for(exact_candidate)).to eq(10)
    expect(points_for(exact_real_score)).to eq(0)
    expect(match).not_to have_received(:home_score)
    expect(match).not_to have_received(:away_score)
  end

  it 'chama ScoringRule#points_for com o palpite e o placar candidato, pela regra de cada bolão' do
    predict(2, 1)
    rule = Bolao::ScoringRule.for(pool)
    allow(Bolao::ScoringRule).to receive(:by_pool).and_return(pool.id => rule)
    allow(rule).to receive(:points_for).and_call_original

    preview(3, 1)

    expect(rule).to have_received(:points_for).with(2, 1, 3, 1)
  end

  it 'retorna Preview (Data.define) imutável com rows e total' do
    predict(2, 1)
    predict(1, 0)
    predict(1, 1, in_pool: create(:bolao_pool))

    result = preview

    expect(Bolao::Preview.superclass).to eq(Data)
    expect(result).to be_frozen
    expect(result.rows).to be_frozen
    expect(result.rows.map(&:points)).to eq([10, 5, 0])
    expect(result.total).to eq(15)
  end

  it 'ignora palpites descartados' do
    predict(2, 1).discard

    expect(preview).to have_attributes(rows: [], total: 0)
  end

  it 'é dry-run: zero writes' do
    predict(2, 1)
    writes = []
    callback = lambda do |*, payload|
      writes << payload[:sql] if payload[:sql].match?(/\A\s*(INSERT|UPDATE|DELETE)/i)
    end

    expect do
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { preview }
    end.not_to change(Bolao::PredictionScore, :count)
    expect(writes).to be_empty
  end

  describe 'validação dos candidatos' do
    [-1, nil, 'dois', 1.5, '-2'].each do |invalid|
      it "rejeita #{invalid.inspect} com ArgumentError" do
        expect { preview(invalid, 1) }.to raise_error(ArgumentError, /candidate_home must be an integer >= 0/)
        expect { preview(1, invalid) }.to raise_error(ArgumentError, /candidate_away must be an integer >= 0/)
      end
    end

    it 'aceita inteiros vindos de params ("2", "0")' do
      predict(2, 0)

      expect(preview('2', '0').total).to eq(10)
    end
  end
end
