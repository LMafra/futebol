require 'rails_helper'

RSpec.describe Bolao::MyBetsComponent do
  it_behaves_like 'a ui component with four states', preview: Bolao::MyBetsComponentPreview

  def result(kind, points, home_score: 2, away_score: 1)
    match = Core::Match.new(home_team: Core::Team.new(name: 'Flamengo'), away_team: Core::Team.new(name: 'Palmeiras'),
                            home_score:, away_score:)
    Bolao::BetResults::Result.new(prediction: Bolao::Prediction.new(match:, home_guess: 2, away_guess: 1),
                                  result: kind, points:)
  end

  it 'renders one row per bet with result and points' do
    page = render_inline(described_class.new(results: [result(:exact, 10), result(:miss, 0)]))

    rows = page.css('[data-role="my-bet"]')
    expect(rows.map { |row| row['data-result'] }).to eq(%w[exact miss])
    expect(rows.map { |row| row.at_css('[data-role="points"]').text }).to eq(%w[10 0])
    expect(rows.first.text).to include('Exato')
  end

  it 'uses the pitch header inside a rounded horizontal scroll wrapper' do
    page = render_inline(described_class.new(results: [result(:exact, 10)]))

    expect(page.at_css('[data-role="table-scroll"]')['class'].split).to include('overflow-x-auto', 'rounded-md')
    expect(page.at_css('thead')['class'].split).to include('bg-pitch', 'text-paper')
    expect(page.css('thead th').map { _1['scope'] }.uniq).to eq(['col'])
  end

  it 'shows a dash for pending bets' do
    page = render_inline(described_class.new(results: [result(:pending, nil, home_score: nil, away_score: nil)]))

    expect(page.at_css('[data-role="points"]').text).to eq('–')
    expect(page.text).to include('Aguardando')
  end

  it 'shows an empty notice without bets' do
    expect(render_inline(described_class.new(results: [])).text).to include('Você ainda não palpitou neste bolão.')
  end
end
