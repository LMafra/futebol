require 'rails_helper'

RSpec.describe 'Championship and team pages, breadcrumbs and "Sobre esta tela" (TICKET-0094)', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, name: 'Copa da Várzea') }
  let(:page) { Nokogiri::HTML(response.body) }

  before { sign_in(manager) }

  def crumbs = page.css('nav[aria-label="breadcrumb"] a').map { |a| a.text.strip }

  it 'shows the matches by round and the bolões on the championship page' do
    first_round = create(:match, championship:, round: 1)
    create(:match, championship:, round: 2)
    pool = create(:bolao_pool, championship:, owner: manager, name: 'Bolão da firma')
    pool.memberships.create!(user: create(:user))

    get "/gestor/championships/#{championship.id}"

    rounds = page.css('details[data-role="collection-group"]').map { |group| group.at_css('summary').text.squish }
    expect(rounds).to contain_exactly(a_string_including('Rodada 1'), a_string_including('Rodada 2'))
    expect(page.at_css("a[href='/gestor/matches/#{first_round.id}']")).to be_present
    expect(page.text).to include('Partidas (2)', 'Bolões (1)', 'Bolão da firma', pool.code)
    expect(page.at_css("#championship-#{championship.id}-pools").text.squish).to match(/Participantes:? ?1/)
  end

  it 'offers the next step when the championship has no matches or bolões' do
    create_list(:team, 2, manager:).each { |team| championship.championship_teams.create!(team:) }

    get "/gestor/championships/#{championship.id}"

    labels = page.css('a').map { |a| a.text.strip }
    expect(labels).to include('Agendar partida', 'Criar bolão')
  end

  it "lists the team's players with a shortcut to add one" do
    team = create(:team, manager:)
    create(:player, team:, name: 'Zé do Gol')

    get "/gestor/teams/#{team.id}"

    expect(page.text).to include('Jogadores (1)', 'Zé do Gol')
    expect(page.at_css("a[href*='player%5Bteam_id%5D=#{team.id}']")).to be_present
  end

  it 'puts the match under its championship in the breadcrumbs' do
    match = create(:match, championship:)

    get "/gestor/matches/#{match.id}"

    expect(crumbs).to eq(['Gestor', 'Campeonatos', championship.to_s, 'Partidas'])
  end

  it 'puts the player under his team in the breadcrumbs' do
    team = create(:team, manager:, name: 'Unidos do Morro')
    player = create(:player, team:)

    get "/gestor/players/#{player.id}/edit"

    expect(crumbs).to eq(['Gestor', 'Times', 'Unidos do Morro', 'Jogadores', player.name])
  end

  it 'explains the screen in "Sobre esta tela", open by default' do
    get '/gestor/championships'

    intro = page.at_css('details[data-role="page-intro"]')
    expect(intro.key?('open')).to be(true)
    expect(intro.at_css('summary').text).to eq('Sobre esta tela')
    expect(intro.text).to include('rascunhos')
    expect(intro['data-dismissible-key-value']).to eq('gestor/championships#index')
  end
end
