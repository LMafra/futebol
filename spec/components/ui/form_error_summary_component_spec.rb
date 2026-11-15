require 'rails_helper'

RSpec.describe Ui::FormErrorSummaryComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::FormErrorSummaryComponentPreview

  it 'renders the count banner and messages without acting as a toast' do
    page = render_inline(described_class.new(count: 2, messages: ['Nome é obrigatório', 'E-mail inválido']))

    expect(page.at_css('[data-role="form-error-summary-title"]').text).to include('2 campos precisam de atenção')
    expect(page.text).to include('Nome é obrigatório', 'E-mail inválido')
    expect(page.at_css('[data-role="admin-toast"]')).to be_nil
  end

  it 'does not render when there are no errors' do
    expect(render_inline(described_class.new(count: 0)).to_html).to eq('')
  end
end
