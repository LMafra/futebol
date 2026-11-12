require 'rails_helper'

RSpec.describe Cartola::RankingTableComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::RankingTableComponentPreview

  def row(position, name, value) = Cartola::RankingsService::Row.new(position:, user: Core::User.new(name:), value:)

  it 'lists position, user and points' do
    page = render_inline(described_class.new(rows: [row(1, 'Ana', BigDecimal('12.5')), row(2, 'Bia', 3)]))

    expect(page.css('[data-role="ranking-row"]').map { |tr| tr.text.squish }).to eq(['1 Ana 12.50', '2 Bia 3.00'])
  end

  it 'uses the pitch header inside a horizontal scroll wrapper' do
    page = render_inline(described_class.new(rows: [row(1, 'Ana', 1)]))

    expect(page.at_css('[data-role="table-scroll"]')['class']).to include('overflow-x-auto')
    expect(page.at_css('thead')['class'].split).to include('bg-pitch', 'text-paper')
  end

  it 'shows coins as money' do
    page = render_inline(described_class.new(rows: [row(1, 'Ana', 80)], kind: :coins))

    expect(page.at_css('[data-role="ranking-value"]').text).to eq('C$ 80.00')
  end

  it 'falls back to the empty state without rows' do
    page = render_inline(described_class.new(rows: []))

    expect(page.at_css('[data-ui-state]')['data-ui-state']).to eq('empty')
  end
end
