require 'rails_helper'

RSpec.describe Ui::PreviewPanelComponent do
  let(:preview) do
    described_class::Preview.new(home_team: 'Flamengo', away_team: 'Palmeiras', home_score: 2, away_score: 1,
                                 entries: [described_class::Entry.new(participant: 'Ana', points: 10),
                                           described_class::Entry.new(participant: 'Bruno', points: 3)])
  end

  it_behaves_like 'a ui component with four states', preview: Ui::PreviewPanelComponentPreview

  it 'requires a preview in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /preview is required/)
  end

  it 'renders simulated points per participant and the total' do
    page = render_inline(described_class.new(preview:))

    expect(page.at_css('[data-role="candidate-score"]').text.squish).to eq('2 × 1')
    entries = page.css('[data-role="preview-entry"]').map { |entry| entry.text.squish }
    expect(entries).to eq(['Ana +10 pts', 'Bruno +3 pts'])
    expect(page.at_css('[data-role="total-points"]').text).to eq('13 pts')
  end

  it 'renders skeletons while loading' do
    expect(render_inline(described_class.new(state: :loading)).css('[data-role="skeleton"]')).to be_present
  end

  it 'asks for a candidate score when empty' do
    expect(render_inline(described_class.new(state: :empty)).text).to include('Informe um placar candidato')
  end

  it 'shows the service error' do
    page = render_inline(described_class.new(state: :error, error_message: 'Partida não encerrada'))

    expect(page.at_css('[data-role="error-message"]').text).to eq('Partida não encerrada')
  end
end
