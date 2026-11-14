require 'rails_helper'

RSpec.describe Cartola::BudgetBarComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::BudgetBarComponentPreview

  it 'requires spent and budget in the default state' do
    expect { described_class.new(budget: 100) }.to raise_error(ArgumentError, /spent is required/)
    expect { described_class.new(spent: 1) }.to raise_error(ArgumentError, /budget is required/)
  end

  it 'shows what was spent and what remains' do
    page = render_inline(described_class.new(spent: BigDecimal('87.5'), budget: BigDecimal(100)))

    expect(page.at_css('[data-role="budget-spent"]').text.squish).to eq('Gasto C$ 87.50')
    expect(page.at_css('[data-role="budget-remaining"]').text.squish).to eq('Resta C$ 12.50 de C$ 100.00')
  end

  it 'flags a lineup over the budget' do
    page = render_inline(described_class.new(spent: BigDecimal('101'), budget: BigDecimal(100)))

    expect(page.at_css('[data-role="budget-remaining"]').text.squish).to start_with('Estourou C$ 1.00')
    expect(page.at_css('[role="progressbar"]')['aria-valuenow']).to eq('100.0')
  end

  it 'names the progress bar and reads the value as money, on a track with 3:1 contrast' do
    page = render_inline(described_class.new(spent: BigDecimal('87.5'), budget: BigDecimal(100)))
    bar = page.at_css('[role="progressbar"]')

    expect(bar['aria-label']).to eq('Orçamento usado')
    expect(bar['aria-valuetext']).to eq('Gasto C$ 87.50 de C$ 100.00')
    expect(bar['class'].split).to include('bg-graphite/30')
  end
end
