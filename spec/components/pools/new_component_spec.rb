require 'rails_helper'

RSpec.describe Pools::NewComponent do
  it_behaves_like 'a ui component with four states', preview: Pools::NewComponentPreview

  let(:championships) { [create(:championship)] }

  it 'requires a pool in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /pool is required/)
  end

  it 'renders the form with the championships' do
    page = render_inline(described_class.new(pool: Bolao::Pool.new, championships:))

    expect(page.at_css('form[action="/pools"]')).to be_present
    expect(page.css('select option').map(&:text)).to eq(championships.map(&:to_s))
  end

  it 'shows field errors in the error state' do
    pool = Bolao::Pool.new.tap(&:validate)
    page = render_inline(described_class.new(pool:, championships:, state: :error))

    expect(page.at_css('[data-role="errors"]')).to be_present
    expect(page.at_css('[data-role="field-error"]')).to be_present
  end
end
