require 'rails_helper'

RSpec.describe 'Histórico da partida (TICKET-0112)', type: :request do
  let(:manager) { create(:user, :manager, name: 'Gestor Teste') }
  let(:match) do
    create(:match, championship: create(:championship, manager:), status: 'live', match_date: 1.hour.ago)
  end
  let!(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Atacante Casa') }
  let!(:rival) { create(:player, team: match.away_team, position: 'ATA', name: 'Atacante Fora') }

  before { create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8) }

  def page = Nokogiri::HTML5(response.body)
  def entries = page.css('[data-role="history-entry"]')

  def record(player)
    post "/gestor/matches/#{match.id}/record_event",
         params: { modal: 'lance', return_to: "/gestor/matches/#{match.id}",
                   lance: { player_id: player.id, stat: 'goals', period: 'first_half', minute: '10' } }
  end

  it 'lists what was done to the match, newest first, with who did it' do
    sign_in(manager)
    record(striker)
    post "/gestor/matches/#{match.id}/finalize", params: { modal: 'finalize', return_to: "/gestor/matches/#{match.id}" }
    record(rival)

    get "/gestor/matches/#{match.id}"

    expect(page.at_css('[data-role="match-history"] h3').text).to eq('Histórico da partida')
    expect(entries.map { _1.at_css('[data-role="history-text"]').text.squish }).to eq(
      ['Placar e pontos refeitos: 1 × 0 → 1 × 1', "Lance registrado: Gol · Atacante Fora · 10' · 1º tempo",
       'Partida finalizada em 1 × 0 e pontuada', "Lance registrado: Gol · Atacante Casa · 10' · 1º tempo"]
    )
    expect(entries.map { _1.at_css('[data-role="history-author"]').text.squish }.uniq).to eq(['Gestor Teste'])
    expect(entries.first.at_css('time')['datetime']).to be_present
  end

  it 'shows the same history on the admin match page, and an empty state before anything happens' do
    sign_in(create(:user, :admin))

    get "/admin/matches/#{match.id}"

    expect(page.at_css('[data-role="match-history"]').text).to include('Nada feito nesta partida ainda.')
  end
end
