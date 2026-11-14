require 'rails_helper'

RSpec.describe Ui::AdminTableComponent do
  let(:headers) do
    [{ label: 'Nome' }, { label: 'Pontos', numeric: true }]
  end
  let(:rows) { [['Ana', 12], ['Bruno', 7]] }

  it_behaves_like 'a ui component with four states', preview: Ui::AdminTableComponentPreview

  it 'renders a pitch thead, zebra rows and right-aligned numeric cells' do
    page = render_inline(described_class.new(headers:, rows:, texts: { label: 'Ranking' }))

    expect(page.at_css('section')['aria-label']).to eq('Ranking')
    expect(page.at_css('thead')['class']).to include('bg-pitch', 'text-paper')
    expect(page.at_css('thead tr')['class']).to include('text-sm', 'uppercase', 'tracking-wide')
    expect(page.css('[data-role="admin-table-row"]').map { |row| row['class'] })
      .to contain_exactly(a_string_including('bg-paper'), a_string_including('bg-white'))
    expect(page.at_css('th:last-child')['class']).to include('text-right', 'tabular-nums')
    expect(page.at_css('[data-role="admin-table-row"] td:last-child')['class'])
      .to include('text-right', 'tabular-nums')
  end

  it 'shows the empty notice when there are no rows' do
    page = render_inline(described_class.new(headers:, rows: [], texts: { empty: 'Vazio.' }))

    expect(page.text).to include('Vazio.')
    expect(page.at_css('section')['data-ui-state']).to eq('empty')
  end
end
