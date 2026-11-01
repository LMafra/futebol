require 'rails_helper'

RSpec.describe Cartola::PitchComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::PitchComponentPreview

  def count_on(page, slot, role) = page.css("[data-slot='#{slot}'] [data-role='#{role}']").size

  it 'places the players on their slots, with the prices given' do
    lineup = create(:cartola_lineup, formation: '4-3-3')
    prices = lineup.players.to_h { |player| [player.id, BigDecimal('7.5')] }
    page = render_inline(described_class.new(lineup:, prices:))

    counts = %w[forward midfielder defender goalkeeper].to_h { |slot| [slot, count_on(page, slot, 'pitch-player')] }
    expect(counts).to eq('forward' => 3, 'midfielder' => 3, 'defender' => 2, 'goalkeeper' => 1)
    expect(page.at_css('[data-role="formation"]').text).to include('4-3-3')
    expect(page.text).to include('C$ 7.50')
  end

  it 'shows the open slots of the preset, capped by the championship limits' do
    championship = create(:championship, cartola_defender_limit: 4)
    lineup = create(:cartola_lineup, championship:, formation: '4-4-2',
                                     players: [create(:player, position: 'GOL'), create(:player, position: 'ZAG')])
    page = render_inline(described_class.new(lineup:))

    expect(count_on(page, 'defender', 'pitch-open-slot')).to eq(3)
    expect(count_on(page, 'midfielder', 'pitch-open-slot')).to eq(3)
    expect(count_on(page, 'forward', 'pitch-open-slot')).to eq(2)
    expect(count_on(page, 'goalkeeper', 'pitch-open-slot')).to eq(0)
  end
end
