require 'rails_helper'

RSpec.describe Ui::StandingsTableComponent do
  let(:rows) do
    [
      { position: 1, team_name: 'Flamengo', short_name: 'FLA', played: 3, wins: 2, draws: 1, losses: 0,
        goal_difference: 4, points: 7, form: %w[V E V] },
      { position: 2, team_name: 'Palmeiras', short_name: 'PAL', played: 3, wins: 1, draws: 0, losses: 2,
        goal_difference: -1, points: 3, form: %w[D V D] }
    ]
  end

  it_behaves_like 'a ui component with four states', preview: Ui::StandingsTableComponentPreview

  it 'renders the standings table with tabular numerals and signed goal difference' do
    page = render_inline(described_class.new(rows:))

    expect(page.css('[data-role="standing-row"]').size).to eq(2)
    expect(page.at_css('table')['class']).to include('tabular-nums')
    expect(page.css('[data-role="standing-row"] td').map(&:text)).to include('+4', '-1')
  end

  it 'pairs every win/draw/loss tint with its V/E/D glyph and an accessible label' do
    glyphs = render_inline(described_class.new(rows:)).css('[data-role="form-glyph"]')

    expect(glyphs.map(&:text)).to eq(%w[V E V D V D])
    tints = glyphs.map { |glyph| glyph['class'][/bg-(win|draw|loss)/] }
    expect(tints).to eq(%w[bg-win bg-draw bg-win bg-loss bg-win bg-loss])
    expect(glyphs.first['aria-label']).to eq('Vitória')
  end

  it 'marks the leader with the cartola accent' do
    expect(render_inline(described_class.new(rows:)).css('td.border-cartola').size).to eq(1)
  end

  it 'renders 10 skeleton rows while loading' do
    expect(render_inline(described_class.new(state: :loading)).css('[data-role="skeleton"]').size).to eq(10)
  end

  it 'shows the not-scored message when empty, including default with no rows' do
    expect(render_inline(described_class.new(state: :empty)).text).to include('Rodada ainda não pontuada')

    page = render_inline(described_class.new(rows: []))
    expect(page.at_css('[data-ui-state="empty"]').text).to include('Rodada ainda não pontuada')
  end

  it 'shows an error message with a link to the log' do
    page = render_inline(described_class.new(state: :error, log_path: '/admin/logs'))

    expect(page.at_css('[role="alert"]').text).to include('Não foi possível montar a classificação')
    expect(page.at_css('a[data-role="log-link"]')['href']).to eq('/admin/logs')
  end
end
