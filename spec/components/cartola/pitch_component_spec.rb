require 'rails_helper'

RSpec.describe Cartola::PitchComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::PitchComponentPreview

  it 'places the players on their lines' do
    lineup = create(:cartola_lineup, formation: '4-3-3')
    page = render_inline(described_class.new(lineup:))

    counts = %w[attack midfield defense goalkeeper].to_h do |line|
      [line, page.css("[data-line='#{line}'] [data-role='pitch-player']").size]
    end
    expect(counts).to eq('attack' => 3, 'midfield' => 3, 'defense' => 4, 'goalkeeper' => 1)
    expect(page.at_css('[data-role="formation"]').text).to include('4-3-3')
  end
end
