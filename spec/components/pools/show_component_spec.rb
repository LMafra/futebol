require 'rails_helper'

RSpec.describe Pools::ShowComponent do
  it_behaves_like 'a ui component with four states', preview: Pools::ShowComponentPreview

  let(:owner) { create(:user, name: 'Ana Souza') }
  let(:pool) { create(:bolao_pool, owner:) }

  it 'requires a pool in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /pool is required/)
  end

  it 'shows the code, the members and marks the owner' do
    page = render_inline(described_class.new(pool:, memberships: pool.memberships.includes(:user)))

    expect(page.at_css('[data-role="code"]').text).to eq(pool.code)
    expect(page.at_css('[data-role="members"]').text).to include('Ana Souza', 'Dono')
  end

  it 'shows the delete button only when allowed' do
    memberships = pool.memberships.to_a

    expect(render_inline(described_class.new(pool:, memberships:)).text).not_to include('Excluir bolão')
    expect(render_inline(described_class.new(pool:, memberships:, can_destroy: true)).text).to include('Excluir bolão')
  end
end
