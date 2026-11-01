require 'rails_helper'

RSpec.describe 'Bolão bets', type: :request do
  let(:user) { create(:user) }
  let(:pool) { create(:bolao_pool, owner: user) }
  let(:scheduled_match) { create(:match, championship: pool.championship, match_date: 2.days.from_now) }

  before { sign_in(user) }

  def bet_on(target, home: 2, away: 1)
    post pool_bets_path(pool), params: { prediction: { match_id: target.id, home_guess: home, away_guess: away } }
  end

  def kick_off(target) = target.update_columns(status: 'live', match_date: 1.minute.ago)

  it 'registra palpite em partida scheduled' do
    expect { bet_on(scheduled_match) }.to change(Bolao::Prediction, :count).by(1)

    expect(response).to redirect_to(pool_bets_path(pool))
    expect(Bolao::Prediction.last)
      .to have_attributes(user:, pool:, match: scheduled_match, home_guess: 2, away_guess: 1)
  end

  it 'bloqueia palpite em partida live' do
    kick_off(scheduled_match)

    expect { bet_on(scheduled_match) }.not_to change(Bolao::Prediction, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Palpites encerrados para esta partida.')
  end

  it 'bloqueia palpite em partida finished' do
    scheduled_match.update_columns(status: 'finished', home_score: 1, away_score: 0, match_date: 2.hours.ago)

    expect { bet_on(scheduled_match) }.not_to change(Bolao::Prediction, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'edita o palpite enquanto a partida está scheduled' do
    bet_on(scheduled_match)
    prediction = Bolao::Prediction.last

    patch pool_bet_path(pool, prediction), params: { prediction: { home_guess: 0, away_guess: 0 } }

    expect(response).to redirect_to(pool_bets_path(pool))
    expect(prediction.reload).to have_attributes(home_guess: 0, away_guess: 0)
  end

  it 'bloqueia a edição depois que a partida vira live' do
    bet_on(scheduled_match)
    prediction = Bolao::Prediction.last
    kick_off(scheduled_match)

    patch pool_bet_path(pool, prediction), params: { prediction: { home_guess: 5, away_guess: 5 } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(prediction.reload).to have_attributes(home_guess: 2, away_guess: 1)
  end

  it 'não-membro recebe 403' do
    outsider_pool = create(:bolao_pool)
    outsider_match = create(:match, championship: outsider_pool.championship)

    get pool_bets_path(outsider_pool)
    expect(response).to have_http_status(:forbidden)

    post pool_bets_path(outsider_pool),
         params: { prediction: { match_id: outsider_match.id, home_guess: 1, away_guess: 0 } }
    expect(response).to have_http_status(:forbidden)
    expect(Bolao::Prediction.count).to eq(0)
  end

  it 'mostra resultado e pontos depois que a partida termina e é pontuada' do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
    guesses = { 'exact' => [2, 1], 'winner' => [3, 1], 'miss' => [0, 1] }
    matches = guesses.to_h do |result, (home, away)|
      target = create(:match, championship: pool.championship)
      bet_on(target, home:, away:)
      [result, target]
    end
    matches.each_value do |target|
      target.update_columns(status: 'finished', home_score: 2, away_score: 1, match_date: 2.hours.ago)
      ProcessMatchPointsJob.perform_now(target.id, SecureRandom.uuid)
    end

    get pool_bets_path(pool)

    page = Nokogiri::HTML(response.body)
    results = page.css('[data-role="my-bet"]').to_h do |row|
      [row['data-result'], row.at_css('[data-role="points"]').text.to_i]
    end
    expect(results).to eq('exact' => 10, 'winner' => 5, 'miss' => 0)
  end

  it 'renderiza o countdown até o apito e "Palpites encerrados" quando o horário passou' do
    started = create(:match, championship: pool.championship, match_date: 5.minutes.ago)
    scheduled_match

    get pool_bets_path(pool)

    page = Nokogiri::HTML(response.body)
    countdowns = page.css('[data-controller="countdown"]').to_h do |node|
      [node['data-countdown-deadline-value'], node.text.strip]
    end
    expect(countdowns.keys).to include(scheduled_match.match_date.iso8601, started.match_date.iso8601)
    expect(countdowns[started.match_date.iso8601]).to eq('Palpites encerrados')
    expect(countdowns[scheduled_match.match_date.iso8601]).to match(/\A\d+d \d{2}:\d{2}:\d{2}\z/)
  end
end
