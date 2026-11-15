require 'rails_helper'

RSpec.describe Ui::ActionCenterComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::ActionCenterComponentPreview

  let(:groups) do
    {
      critical: [{ title: 'Flamengo x Palmeiras', context: 'Ao vivo', action_text: 'Finalizar', action_path: '/m/1' }],
      high: [{ title: 'Pontuar', context: 'Encerrada', action_text: 'Finalizar', action_path: '/m/2' }],
      medium: []
    }
  end

  it 'groups items by urgency and filters via URL urgency' do
    page = render_inline(described_class.new(groups:))
    expect(page.css('[data-role="action-center-group"]').map { _1['data-urgency'] }).to eq(%w[critical high])
    expect(page.css('[data-role="action-center-item"]').size).to eq(2)

    filtered = render_inline(described_class.new(groups:, filter_urgency: :critical))
    expect(filtered.css('[data-role="action-center-group"]').map { _1['data-urgency'] }).to eq(%w[critical])
    expect(filtered.at_css('[data-role="action-center-filter"]').text).to include('Crítica')
  end

  it 'renders EmptyState when there are no items' do
    page = render_inline(described_class.new(groups: {}))
    expect(page.at_css('[data-role="empty-state"]').text).to include('Nada na central de ações')
  end
end
