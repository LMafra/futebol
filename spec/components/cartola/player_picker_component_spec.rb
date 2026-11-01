require 'rails_helper'

RSpec.describe Cartola::PlayerPickerComponent do
  it_behaves_like 'a ui component with four states', preview: Cartola::PlayerPickerComponentPreview

  let(:keeper) { create(:player, position: 'GOL') }
  let(:striker) { create(:player, position: 'ATA') }

  it 'groups players by position and checks the selected ones' do
    page = render_inline(described_class.new(players: [keeper, striker], selected_ids: [striker.id]))

    expect(page.css('[data-player-filter-target="group"]').map { |group| group['data-position'] }).to eq(%w[GOL ATA])
    checked = page.css('input[type="checkbox"][checked]').map { |input| input['value'] }
    expect(checked).to eq([striker.id.to_s])
  end

  it 'always submits player_ids, even with nothing checked' do
    page = render_inline(described_class.new(players: [keeper]))

    expect(page.at_css('input[type="hidden"][name="lineup[player_ids][]"]')).to be_present
  end
end
