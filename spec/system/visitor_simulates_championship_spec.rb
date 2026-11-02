require 'rails_helper'

RSpec.describe 'Visitor simulates a championship', type: :system do
  let(:championship) { create(:championship, name: 'Copa Teste') }
  let(:teams) { %w[Alfa Beta Gama Delta].map { |name| create(:team, name:) } }

  before do
    create(:match, championship:, home_team: teams[0], away_team: teams[1], round: 1, status: 'finished',
                   home_score: 2, away_score: 1, match_date: 1.week.ago)
    create(:match, championship:, home_team: teams[2], away_team: teams[3], round: 2)
    create(:match, championship:, home_team: teams[0], away_team: teams[2], round: 3)
  end

  it 'opens on the first open round, goes back to past results and forward through the open rounds' do
    visit root_path
    expect(page.evaluate_script("document.documentElement.classList.contains('snap-mandatory')")).to be(true)
    click_on 'Simular Copa Teste'

    expect(page).to have_text('Rodada 2 · 2 de 3')
    expect(page.evaluate_script("document.documentElement.classList.contains('snap-mandatory')")).to be(false)
    expect(page).to have_field('Gols do Gama')

    click_on 'Rodada anterior'

    expect(page).to have_text('Rodada 1 · 1 de 3')
    expect(page).to have_css('[data-role="closed-match"]', text: 'Alfa')
    expect(page).to have_no_field('Gols do Alfa')
    expect(page).to have_button('Rodada anterior', disabled: true)

    click_on 'Próxima rodada'
    click_on 'Próxima rodada'

    expect(page).to have_text('Rodada 3 · 3 de 3')
    expect(page).to have_field('Gols do Alfa')
    expect(page).to have_button('Próxima rodada', disabled: true)
  end

  it 'swaps the current table for the projected one, and resets the simulation' do
    visit simulador_championship_path(championship)
    expect(page).to have_css('#table-title', text: 'Tabela atual')

    fill_in 'Gols do Gama', with: '3'
    fill_in 'Gols do Delta', with: '0'
    click_on 'Projetar tabela'

    expect(page).to have_css('#table-title', text: 'Tabela projetada')
    expect(page).to have_no_css('[data-role="real-table"]')

    click_on 'Zerar simulação'

    expect(page).to have_css('#table-title', text: 'Tabela atual')
    expect(page).to have_field('Gols do Gama', with: '')
    expect(page).to have_no_link('Zerar simulação')
  end
end
