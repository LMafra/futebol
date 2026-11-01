require 'rails_helper'

RSpec.describe Pools::IndexComponent do
  it_behaves_like 'a ui component with four states', preview: Pools::IndexComponentPreview

  it 'requires pools in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /pools is required/)
  end

  it 'lists pools with their code and the join form' do
    pool = create(:bolao_pool, name: 'Bolão da firma')
    page = render_inline(described_class.new(pools: [pool]))

    expect(page.at_css('[data-role="pools"] a').text).to eq('Bolão da firma')
    expect(page.at_css('[data-role="pools"]').text).to include(pool.code)
    expect(page.at_css('[data-role="join-form"]')).to be_present
  end

  it 'keeps the join form in the empty state' do
    page = render_inline(described_class.new(pools: [], state: :empty))

    expect(page.text).to include('Você ainda não participa de nenhum bolão.')
    expect(page.at_css('[data-role="join-form"]')).to be_present
  end

  it 'shows the error message' do
    page = render_inline(described_class.new(error: 'Código de bolão inválido.', state: :error))

    expect(page.at_css('[data-role="error-message"]').text).to eq('Código de bolão inválido.')
  end
end
