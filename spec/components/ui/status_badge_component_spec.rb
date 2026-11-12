require 'rails_helper'

RSpec.describe Ui::StatusBadgeComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::StatusBadgeComponentPreview

  {
    scheduled: %w[bg-rule text-ink Agendada],
    live: ['bg-cartola', 'text-ink', 'Ao vivo'],
    finished: ['bg-pitch/10', 'text-pitch', 'Encerrada'],
    reverted: %w[bg-loss text-ink Revertida]
  }.each do |status, (bg, color, label)|
    it "renders the #{status} badge" do
      page = render_inline(described_class.new(status:))

      badge = page.at_css('[data-role="status-badge"]')
      expect(badge['class']).to include(bg, color)
      expect(badge['data-status']).to eq(status.to_s)
      expect(badge.text.squish).to eq(label)
    end
  end

  it 'never uses cartola as text colour' do
    described_class::STYLES.each_value { |classes| expect(classes.split).not_to include('text-cartola') }
  end

  it 'rejects unknown statuses' do
    expect { described_class.new(status: :draft) }.to raise_error(ArgumentError, /invalid status/)
  end
end
