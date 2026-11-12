require 'rails_helper'

RSpec.describe Ui::LeaderboardTableComponent do
  let(:rows) do
    [Core::ChampionshipRankingsService::Row.new(position: 1, user_name: 'Ana S.', points: 12),
     Core::ChampionshipRankingsService::Row.new(position: 2, user_name: 'Participante', points: BigDecimal('7.5'))]
  end

  it_behaves_like 'a ui component with four states', preview: Ui::LeaderboardTableComponentPreview

  it 'lists position, name and points, integers as they are and decimals with two places' do
    page = render_inline(described_class.new(rows:, texts: { label: 'Ranking do Bolão' }))

    expect(page.at_css('section')['aria-label']).to eq('Ranking do Bolão')
    expect(page.css('[data-role="leaderboard-row"]').map { |row| row.text.squish })
      .to eq(['1 Ana S. 12', '2 Participante 7.50'])
    expect(page.at_css('tr td')['class']).to include('border-cartola')
    expect(page.at_css('[data-role="medal"]')['data-position']).to eq('1')
    expect(page.at_css('thead')['class']).to include('bg-pitch', 'text-paper')
    expect(page.at_css('[data-role="table-scroll"]')['class']).to include('overflow-x-auto')
  end

  it 'adds the extra columns before the points, with the detail next to the name' do
    player = Data.define(:position, :name, :detail, :games, :points).new(1, 'Pedro', 'FLA', 10, 30)
    page = render_inline(described_class.new(rows: [player], texts: { name_header: 'Atleta' },
                                             columns: { games: %w[J Jogos] }))

    expect(page.css('thead th').map { |cell| cell.text.squish }).to eq(%w[# Atleta J Pts])
    expect(page.at_css('[data-role="leaderboard-row"]').text.squish).to eq('1 Pedro FLA 10 30')
  end

  it 'hides the header from sight and drops the extra columns in the compact variant' do
    page = render_inline(described_class.new(rows:, compact: true, columns: { games: %w[J Jogos] }))

    expect(page.at_css('thead')['class']).to include('sr-only')
    expect(page.css('thead th').size).to eq(3)
  end

  it 'shows the empty message when nobody scored' do
    page = render_inline(described_class.new(rows: [], texts: { empty: 'Sem palpites pontuados.' }))

    expect(page.text).to include('Sem palpites pontuados.')
    expect(page.at_css('section')['data-ui-state']).to eq('empty')
  end
end
