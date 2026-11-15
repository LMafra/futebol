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

  it 'uses pitch checkboxes and a 48px captain chip over a native radio (TICKET-0082)' do
    page = render_inline(described_class.new(players: [striker], selected_ids: [striker.id], captain_id: striker.id))

    expect(page.at_css('input[type="checkbox"][name="lineup[player_ids][]"]')['class']).to include('accent-pitch')
    captain = page.at_css('input[type="radio"][name="lineup[captain_id]"]')
    expect(captain['class'].split).to include('peer', 'sr-only')
    expect(captain.next_element['class'].split).to include('size-12', 'peer-checked:bg-cartola')
  end
end
