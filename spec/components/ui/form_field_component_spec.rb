require 'rails_helper'

RSpec.describe Ui::FormFieldComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::FormFieldComponentPreview

  it 'renders an inline error with autofocus and red border' do
    page = render_inline(described_class.new(name: :name, label: 'Nome', value: '', error: 'é obrigatório'))

    expect(page.at_css('[data-role="form-field-error"]').text).to include('é obrigatório')
    expect(page.at_css('input')['class']).to include('border-red-800')
    expect(page.at_css('input')['autofocus']).to be_present
    expect(page.at_css('input')['value']).to eq('')
  end
end
