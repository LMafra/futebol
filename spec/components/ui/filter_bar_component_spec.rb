require 'rails_helper'

RSpec.describe Ui::FilterBarComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::FilterBarComponentPreview

  it 'renders removable chips, clear-all and saved views' do
    page = render_inline(
      described_class.new(
        chips: [{ label: 'Rodada: 3', remove_path: '/matches?q[status_eq]=live' }],
        clear_path: '/matches',
        views: [
          { key: 'pending', label: 'Minhas Pendências', path: '/matches?scope=pendencias', current: true },
          { key: 'all', label: 'Todas as Partidas', path: '/matches' }
        ]
      )
    ) do |bar|
      bar.with_controls { '<input name="q">'.html_safe }
    end

    expect(page.at_css('[data-role="filter-chip"]').text).to include('Rodada: 3')
    expect(page.at_css('[data-role="filter-clear-all"]')['href']).to eq('/matches')
    expect(page.css('[data-role="filter-view"]').map(&:text).map(&:squish))
      .to eq(['Minhas Pendências', 'Todas as Partidas'])
    expect(page.at_css('[data-role="filter-view"][data-view="pending"]')['aria-current']).to eq('page')
  end
end
