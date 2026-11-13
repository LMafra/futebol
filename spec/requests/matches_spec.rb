require 'rails_helper'

RSpec.describe 'Página pública da partida (/partidas/:id)', type: :request do
  let(:championship) { create(:championship, name: 'Copa Aberta') }
  let(:match) do
    create(:match, championship:, status: 'live', match_date: 1.hour.ago, round: 3, home_score: 0, away_score: 0,
                   home_team: create(:team, name: 'Casa FC'), away_team: create(:team, name: 'Fora EC'))
  end
  let(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Zé do Gol') }
  let(:rival) { create(:player, team: match.away_team, position: 'ZAG', name: 'Beto Zaga') }

  before { create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME) }

  def page = Nokogiri::HTML5(response.body)

  def record(player, stat, minute:, period: 'first_half')
    Scouts::RecordEvent.call(event: Cartola::ScoutEvent.new(match:, player:, stat:, minute:, period:),
                             actor: create(:user, :admin), ip_address: '127.0.0.1')
  end

  it 'mostra o placar, os gols e a linha do tempo, e assina o stream da partida, sem login' do
    record(striker, 'goals', minute: 12)
    record(rival, 'yellow_cards', minute: 30)
    record(rival, 'own_goals', minute: 40, period: 'second_half')

    get public_match_path(match)

    expect(response).to have_http_status(:ok)
    expect(page.at_css('h1').text).to eq('Casa FC × Fora EC')
    expect(page.at_css('[data-role="match-header"] a')['href'])
      .to eq(public_championship_path(championship, tab: 'partidas', rodada: 3))
    live = page.at_css("##{ActionView::RecordIdentifier.dom_id(match, :live)}")
    expect(live.at_css('[data-role="score"]').text.squish).to eq('2×0')
    expect(live.css('[data-role="goals"] ul').first.text.squish).to eq("Zé do Gol 12' Beto Zaga 40' (GC)")
    expect(live.css('[data-role="timeline-event"]').map { _1.text.squish }).to eq(
      ["40' · 2º tempo Gol contra · Beto Zaga (Fora EC)", "30' · 1º tempo Cartão amarelo · Beto Zaga (Fora EC)",
       "12' · 1º tempo Gol · Zé do Gol (Casa FC)"]
    )
    expect(page.at_css('turbo-cable-stream-source')['signed-stream-name']).to be_present
  end

  it 'avisa que a partida agendada ainda não começou' do
    match.update_columns(status: 'scheduled', match_date: 1.day.from_now)

    get public_match_path(match)

    expect(page.at_css('[data-role="timeline"]').text).to include('A partida ainda não começou.')
  end

  it 'dá 404 para rascunho e para campeonato privado a visitantes' do
    championship.update_columns(status: 'draft')
    get public_match_path(match)
    expect(response).to have_http_status(:not_found)

    championship.update_columns(status: 'published', private: true)
    get public_match_path(match)
    expect(response).to have_http_status(:not_found)
  end

  it 'abre partida de campeonato privado para quem participa de um bolão dele' do
    championship.update_columns(private: true)
    member = create(:user)
    create(:bolao_pool, championship:).memberships.create!(user: member)

    sign_in(member)
    get public_match_path(match)

    expect(response).to have_http_status(:ok)
    expect(page.at_css('[data-role="match-header"] a')).to be_nil
  end

  it 'é o destino das partidas na aba Partidas do campeonato e nos jogos de hoje' do
    match.update_columns(match_date: Time.current.change(hour: 12))

    get public_championship_path(championship, tab: 'partidas')
    expect(page.at_css('[data-role="match-row"] a')['href']).to eq(public_match_path(match))

    get root_path
    expect(page.at_css('[data-role="today-match"] a')['href']).to eq(public_match_path(match))
  end
end
