require 'rails_helper'

RSpec.describe Ui::ScoreboardComponent do
  let(:match) do
    Core::Match.new(home_team: Core::Team.new(name: 'Flamengo', short_name: 'FLA'),
                    away_team: Core::Team.new(name: 'Palmeiras', short_name: 'PAL'),
                    match_date: Time.zone.parse('2026-11-08 16:00'), home_score: 2, away_score: 1, status: 'finished')
  end

  it_behaves_like 'a ui component with four states', preview: Ui::ScoreboardComponentPreview

  it 'requires a match in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /match is required/)
  end

  it 'renders the TV scoreboard (2/8/2) with display-serif names and tabular score' do
    page = render_inline(described_class.new(match:))

    expect(page.css('[data-ui-state="default"] .col-span-2').size).to eq(2)
    expect(page.css('[data-ui-state="default"] .col-span-8').size).to eq(1)
    expect(page.css('.font-display.text-2xl').map(&:text)).to eq(%w[Flamengo Palmeiras])
    expect(page.at_css('[data-role="score"]')['class']).to include('tabular-nums')
    expect(page.at_css('[data-role="score"]').text.squish).to eq('2×1')
    expect(page.at_css('[data-role="status"]').text).to eq('Encerrado')
  end

  it 'highlights live matches with the single cartola accent' do
    match.status = 'live'

    expect(render_inline(described_class.new(match:)).at_css('[data-role="status"].bg-cartola').text).to eq('Ao vivo')
  end

  it 'renders 64px skeleton rows while loading' do
    page = render_inline(described_class.new(state: :loading))

    expect(page.css('[data-role="skeleton"].h-16').size).to eq(3)
    expect(page.at_css('[aria-busy="true"]')).to be_present
  end

  it 'shows the empty-round message' do
    expect(render_inline(described_class.new(state: :empty)).text).to include('Sem jogos nesta rodada')
  end

  it 'shows a loss-tinted band with a Turbo retry link inside the frame' do
    page = render_inline(described_class.new(state: :error, retry_path: '/rodada/1'))

    expect(page.at_css('turbo-frame [role="alert"].bg-loss')).to be_present
    expect(page.at_css('turbo-frame a[data-role="retry"]')['href']).to eq('/rodada/1')
  end
end
