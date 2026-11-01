require 'rails_helper'

RSpec.describe Cartola::BudgetBarComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::BudgetBarComponentPreview

  it 'requires spent in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /spent is required/)
  end

  it 'shows what was spent and what remains' do
    page = render_inline(described_class.new(spent: BigDecimal('87.5')))

    expect(page.at_css('[data-role="budget-spent"]').text.squish).to eq('Gasto C$ 87.50')
    expect(page.at_css('[data-role="budget-remaining"]').text.squish).to eq('Resta C$ 12.50 de C$ 100.00')
  end

  it 'flags a lineup over the budget' do
    page = render_inline(described_class.new(spent: BigDecimal('101')))

    expect(page.at_css('[data-role="budget-remaining"]').text.squish).to start_with('Estourou C$ 1.00')
  end
end
