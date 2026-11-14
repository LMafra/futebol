require 'rails_helper'

RSpec.describe Ui::FormSectionComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::FormSectionComponentPreview

  it 'renders a titled section as a white surface with rule border' do
    page = render_inline(described_class.new(title: 'Esquadrão')) do |section|
      section.with_body { 'Limites e orçamento.' }
    end

    expect(page.at_css('[data-role="form-section"]')['class']).to include('border-rule', 'bg-white')
    expect(page.at_css('h3').text).to eq('Esquadrão')
    expect(page.at_css('h3')['class']).to include('font-display', 'text-xl')
    expect(page.text).to include('Limites e orçamento.')
  end
end
