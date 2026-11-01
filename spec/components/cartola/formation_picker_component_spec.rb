require 'rails_helper'

RSpec.describe Cartola::FormationPickerComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::FormationPickerComponentPreview

  it 'renders one radio per formation with the selected one checked' do
    page = render_inline(described_class.new(selected: '3-5-2'))

    radios = page.css('input[name="lineup[formation]"]')
    expect(radios.map { |radio| radio['value'] }).to eq(Cartola::Lineup::FORMATIONS)
    expect(radios.find { |radio| radio['checked'] }['value']).to eq('3-5-2')
  end

  it 'keeps the options next to the error message' do
    page = render_inline(described_class.new(selected: '4-3-3', error_message: 'Formação inválida.', state: :error))

    expect(page.at_css('[role="alert"]').text).to include('Formação inválida.')
    expect(page.css('input[name="lineup[formation]"]')).to be_present
  end
end
