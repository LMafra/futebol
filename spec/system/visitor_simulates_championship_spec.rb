require 'rails_helper'

RSpec.describe 'Visitor simulates a championship', type: :system do
  let(:championship) { create(:championship, name: 'Copa Teste') }
  let(:teams) { %w[Alfa Beta Gama Delta].map { |name| create(:team, name:) } }

  before do
    create(:match, championship:, home_team: teams[0], away_team: teams[1], round: 1)
    create(:match, championship:, home_team: teams[2], away_team: teams[3], round: 2)
  end

  it 'picks the championship and walks through the open rounds one at a time' do
    visit simulador_path
    click_on 'Simular Copa Teste'

    expect(page).to have_text('Rodada 1 · 1 de 2')
    expect(page).to have_field('Gols do Alfa')
    expect(page).to have_no_field('Gols do Gama')
    expect(page).to have_button('Rodada anterior', disabled: true)

    click_on 'Próxima rodada'

    expect(page).to have_text('Rodada 2 · 2 de 2')
    expect(page).to have_field('Gols do Gama')
    expect(page).to have_no_field('Gols do Alfa')
    expect(page).to have_button('Próxima rodada', disabled: true)
  end
end
