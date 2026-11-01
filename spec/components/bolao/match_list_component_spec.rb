require 'rails_helper'

RSpec.describe Bolao::MatchListComponent do
  it_behaves_like 'a ui component with four states', preview: Bolao::MatchListComponentPreview

  let(:pool) { create(:bolao_pool) }

  it 'renders a form for scheduled matches and closes live ones' do
    scheduled = create(:match, championship: pool.championship, match_date: 1.day.from_now + 2.hours)
    live = create(:match, championship: pool.championship, match_date: 10.minutes.ago, status: 'live')
    page = render_inline(described_class.new(pool:, matches: [scheduled, live]))

    rows = page.css('[data-role="match"]')
    expect(rows.first.at_css('form')).to be_present
    expect(rows.first.at_css('[data-controller="countdown"]').text).to match(/\A1d 0[12]:\d{2}:\d{2}\z/)
    expect(rows.last.at_css('form')).to be_nil
    expect(rows.last.at_css('[data-controller="countdown"]').text).to eq('Palpites encerrados')
  end

  it 'prefills the user bet' do
    match = create(:match, championship: pool.championship)
    bet = create(:bolao_prediction, pool:, match:, home_guess: 3, away_guess: 2)
    page = render_inline(described_class.new(pool:, matches: [match], bets_by_match: { match.id => bet }))

    expect(page.at_css('input[name="prediction[home_guess]"]')['value']).to eq('3')
    expect(page.at_css('input[type="submit"]')['value']).to eq('Atualizar')
  end

  it 'shows an empty notice without matches' do
    expect(render_inline(described_class.new(pool:, matches: [])).text).to include('Sem jogos abertos para palpite.')
  end
end
