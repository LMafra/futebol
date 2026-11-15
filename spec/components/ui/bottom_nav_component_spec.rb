require 'rails_helper'

RSpec.describe Ui::BottomNavComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::BottomNavComponentPreview

  it 'renders up to four items plus Mais, with 44pt targets' do
    page = render_inline(
      described_class.new(
        items: [
          { label: 'Início', path: '/gestor', current: true },
          { label: 'Partidas', path: '/gestor/matches' },
          { label: 'Times', path: '/gestor/teams' },
          { label: 'Campeonatos', path: '/gestor/championships' }
        ]
      )
    )

    expect(page.css('[data-role="bottom-nav-item"]').size).to eq(4)
    expect(page.at_css('[data-role="admin-bottom-nav-more"]').text).to include('Mais')
    expect(page.at_css('nav')['class']).to include('sm:hidden', 'fixed')
    expect(page.at_css('[data-role="bottom-nav-item"]')['class']).to include('min-h-14')
  end
end
