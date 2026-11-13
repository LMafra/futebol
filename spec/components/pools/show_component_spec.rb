require 'rails_helper'

RSpec.describe Pools::ShowComponent do
  it_behaves_like 'a ui component with four states', preview: Pools::ShowComponentPreview

  let(:owner) { create(:user, name: 'Ana Souza') }
  let(:pool) { create(:bolao_pool, owner:) }

  it 'requires a pool in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /pool is required/)
  end

  it 'shows the code, the organizer and the members' do
    pool.memberships.create!(user: create(:user, name: 'Bruno Lima'))
    page = render_inline(described_class.new(pool:, memberships: pool.memberships.includes(:user)))

    expect(page.at_css('[data-role="code"]').text).to eq(pool.code)
    expect(page.at_css('[data-role="organizer"]').text).to eq('Organizado por Ana Souza')
    expect(page.at_css('[data-role="members"]').text).to include('Bruno Lima')
  end

  it 'shows the delete button only when allowed' do
    memberships = pool.memberships.to_a

    expect(render_inline(described_class.new(pool:, memberships:)).text).not_to include('Excluir bolão')
    page = render_inline(described_class.new(pool:, memberships:, can_destroy: true))
    expect(page.text).to include('Excluir bolão')
    delete_button = page.at_css('form button, form input[type="submit"]')
    expect(delete_button['class'].split).to include('bg-loss-solid', 'text-white')
  end
end
