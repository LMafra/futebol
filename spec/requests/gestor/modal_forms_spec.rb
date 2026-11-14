require 'rails_helper'

RSpec.describe 'Creation dialogs (TICKET-0095)', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }
  let(:team) { create(:team, manager:, name: 'Unidos do Morro') }

  before { sign_in(manager) }

  def page = Nokogiri::HTML5(response.body)
  def dialog(id) = page.at_css("dialog#modal-#{id}")

  it 'opens "Cadastrar jogador" in a dialog, with the full page as the link target' do
    get "/gestor/teams/#{team.id}"

    trigger = page.css('[data-modal-open="modal-player"]').first
    expect(trigger['href']).to include('/gestor/players/new')
    expect(dialog(:player)).to be_present
    expect(dialog(:player).key?('open')).to be(false)
    expect(dialog(:player).at_css('input[name="return_to"]')['value']).to eq("/gestor/teams/#{team.id}")
  end

  it 'goes back to the team page after creating the player' do
    params = { player: { team_id: team.id, name: 'Zé do Gol', position: 'ATA' }, modal: 'player',
               return_to: "/gestor/teams/#{team.id}" }

    expect { post '/gestor/players', params: }.to change(team.players, :count).by(1)
    expect(response).to redirect_to("/gestor/teams/#{team.id}")
    expect(flash[:notice]).to eq('Jogador cadastrado: Zé do Gol.')
  end

  it 'reopens the dialog with the errors and the typed values' do
    params = { player: { team_id: team.id, name: 'Zé do Gol', position: '' }, modal: 'player',
               return_to: "/gestor/teams/#{team.id}" }

    post('/gestor/players', params:)
    expect(response).to redirect_to("/gestor/teams/#{team.id}?modal=player")

    follow_redirect!
    expect(dialog(:player).key?('open')).to be(true)
    expect(dialog(:player).at_css('[role="alert"]').text).to include('Posição')
    expect(dialog(:player).at_css('#player_name')['value']).to eq('Zé do Gol')
    expect(dialog(:player).at_css('#player_position')['aria-invalid']).to eq('true')
    expect(page.css('[data-role="craquefy-admin-flashes"]')).to be_empty
  end

  it 'ignores a return_to outside the namespace' do
    params = { player: { team_id: team.id, name: 'Zé', position: 'ATA' }, modal: 'player', return_to: '//evil.test/x' }

    post('/gestor/players', params:)
    expect(response).to redirect_to("/gestor/players/#{Core::Player.last.id}")
  end

  it 'creates the bolão from the championship page and stays there' do
    get "/gestor/championships/#{championship.id}"
    expect(dialog(:pool)).to be_present

    post '/gestor/pools', params: { pool: { championship_id: championship.id, name: 'Bolão da firma' }, modal: 'pool',
                                    return_to: "/gestor/championships/#{championship.id}" }
    expect(response).to redirect_to("/gestor/championships/#{championship.id}")
    expect(flash[:notice]).to eq("Bolão criado. Compartilhe o código #{Bolao::Pool.last.code}.")
  end

  it 'reopens "Agendar partida" when the same team plays both sides' do
    home, away = create_list(:team, 2, manager:)
    [home, away].each { |enrolled| championship.championship_teams.create!(team: enrolled) }
    params = { match: { championship_id: championship.id, home_team_id: home.id, away_team_id: home.id,
                        match_date: 2.days.from_now.strftime('%Y-%m-%dT%H:%M') },
               modal: 'match', return_to: "/gestor/championships/#{championship.id}" }

    expect { post '/gestor/matches', params: }.not_to change(Core::Match, :count)
    follow_redirect!
    expect(dialog(:match).key?('open')).to be(true)
    expect(dialog(:match).at_css('#match_home_team_id option[selected]')['value']).to eq(home.id.to_s)
  end

  it 'enrolls a team from the dialog and reopens it when the team is not allowed' do
    foreign = create(:team, manager: create(:user, :manager))
    team

    get "/gestor/championships/#{championship.id}"
    expect(dialog(:enroll).css('#team_id option').map(&:text).compact_blank).to eq(['Unidos do Morro'])

    post "/gestor/championships/#{championship.id}/enroll",
         params: { team_id: foreign.id, modal: 'enroll', return_to: "/gestor/championships/#{championship.id}" }
    follow_redirect!
    expect(dialog(:enroll).key?('open')).to be(true)
    expect(dialog(:enroll).at_css('[role="alert"]')).to be_present
  end

  it 'opens "Novo time" from the teams list and comes back to it' do
    get '/gestor/teams'
    expect(page.at_css('[data-modal-open="modal-team"]').text).to eq('Novo time')
    expect(dialog(:team).at_css('form')['enctype']).to eq('multipart/form-data')

    post '/gestor/teams', params: { team: { name: 'Vila Nova', short_name: 'vil' }, modal: 'team',
                                    return_to: '/gestor/teams' }
    expect(response).to redirect_to('/gestor/teams')
    expect(flash[:notice]).to eq('Time cadastrado: Vila Nova.')
  end
end
