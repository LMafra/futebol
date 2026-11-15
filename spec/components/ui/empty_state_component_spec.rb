require 'rails_helper'

RSpec.describe Ui::EmptyStateComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::EmptyStateComponentPreview

  it 'renders SVG, title, description and CTA without emoji' do
    page = render_inline(described_class.new(title: 'Sem partidas', description: 'Agende a primeira.')) do |empty|
      empty.with_action { 'Agendar' }
    end

    root = page.at_css('[data-role="empty-state"]')
    expect(root.at_css('svg')).to be_present
    expect(root.text).to include('Sem partidas', 'Agende a primeira.', 'Agendar')
    expect(root.text).not_to match(/[\u{1F300}-\u{1FAFF}]/)
  end

  {
    'Você ainda não está em nenhum bolão' => 'Peça o código ao organizador.',
    'Monte sua primeira escalação' => 'Escolha a formação e compre jogadores.',
    'Nenhum bolão encontrado' => 'Tente outro nome ou peça o código ao organizador.'
  }.each do |title, description|
    it "renders contextual empty state: #{title}" do
      page = render_inline(described_class.new(title:, description:))
      expect(page.at_css('[data-role="empty-state"]').text).to include(title, description)
      expect(page.text).not_to include('bolão público')
    end
  end
end

