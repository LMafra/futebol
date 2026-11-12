require 'rails_helper'

RSpec.describe 'Gestor dashboard', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, name: 'Copa do Gestor') }

  before { sign_in(manager) }

  def page_html = Nokogiri::HTML(response.body)

  def queue_row(match) = page_html.at_css("[data-role='queue-match'][data-match-id='#{match.id}']")

  it 'shows championship cards, the queue KPIs and the match queue' do
    championship

    get '/gestor'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Copa do Gestor', 'data-role="gestor-championships"')
    expect(page_html.css('[data-role="gestor-kpi"]').map { _1['data-label'] })
      .to eq(['Partidas hoje', 'Aguardando scouts', 'Aguardando finalização'])
    expect(response.body).to include('data-role="gestor-match-queue"', 'Fila de partidas')
    expect(page_html.at_css('[data-role="gestor-championships"]').text).not_to include('Finalizar')
    order = %w[gestor-kpis gestor-match-queue gestor-championships].map { response.body.index("data-role=\"#{_1}\"") }
    expect(order).to eq(order.sort)
  end

  it 'exposes at most one filled CTA per match, matching its state' do
    future = create(:match, championship:, match_date: 2.days.from_now)
    live = create(:match, championship:, status: 'live', match_date: 1.hour.ago)
    scored = create(:match, championship:, status: 'scored', match_date: 1.day.ago, home_score: 1, away_score: 0,
                            scores_calculated_at: 20.hours.ago)

    get '/gestor'

    expect(queue_row(future).css('[data-role="queue-cta"]').map(&:text)).to eq(['Editar partida'])
    expect(queue_row(live).css('[data-role="queue-cta"]').map(&:text)).to eq(['Lançar scouts'])
    expect(queue_row(scored).css('[data-role="queue-cta"]')).to be_empty
    expect(queue_row(scored).at_css('[data-role="status-badge"]').text.squish).to eq('Pontuada')
  end

  it 'labels a finished match as scoring, with no CTA' do
    finished = create(:match, championship:, status: 'finished', match_date: 3.hours.ago, home_score: 0,
                              away_score: 0)

    get '/gestor'

    expect(queue_row(finished).at_css('[data-role="status-badge"]').text.squish).to eq('Pontuando')
    expect(queue_row(finished).css('[data-role="queue-cta"]')).to be_empty
  end

  it 'keeps Reverter only inside the row overflow, never as a global shortcut' do
    scored = create(:match, championship:, status: 'scored', match_date: 1.day.ago, home_score: 1, away_score: 0,
                            scores_calculated_at: 20.hours.ago)

    get '/gestor'

    revert = queue_row(scored).at_css('details[data-role="queue-overflow"] [data-role="queue-revert"]')
    expect(revert['href']).to eq(gestor_matchreversal_path(match_id: scored.id))
    content_links = page_html.css('a').reject { _1.ancestors('#main-menu').any? }
    expect(content_links.select { _1.text.include?('Reverter') }.size).to eq(1)
  end
end
