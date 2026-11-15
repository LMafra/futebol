require 'rails_helper'

RSpec.describe 'Gestor: times e inscrições', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, name: 'Copa do Bairro') }
  let!(:own_team) { create(:team, manager:, name: 'Unidos da Vila') }
  let!(:foreign_team) { create(:team, manager: create(:user, :manager), name: 'Time Alheio') }

  before { sign_in(manager) }

  it 'lista só os times do gestor' do
    get '/gestor/teams'

    expect(response.body).to include('Unidos da Vila')
    expect(response.body).not_to include('Time Alheio')
  end

  it 'não abre time de outro gestor' do
    get "/gestor/teams/#{foreign_team.id}"

    expect(response).to have_http_status(:forbidden).or redirect_to('/gestor')
  end

  it 'cria o time como do gestor, com o capitão' do
    post '/gestor/teams', params: { team: { name: 'Novo FC', short_name: 'NFC', captain_name: 'Ana',
                                            captain_phone: '(11) 98765-4321' } }

    team = Core::Team.find_by!(name: 'Novo FC')
    expect(team).to have_attributes(manager:, captain_name: 'Ana', captain_phone: '11987654321')
    follow_redirect!
    expect(response.body).to include('(11) 98765-4321')
  end

  it 'inscreve um time seu no campeonato pela página dele' do
    get "/gestor/championships/#{championship.id}"
    expect(response.body).to include('Times inscritos (0)', 'Inscrever time')

    post "/gestor/championships/#{championship.id}/enroll", params: { team_id: own_team.id }

    expect(championship.teams).to contain_exactly(own_team)
    follow_redirect!
    expect(response.body).to include('Unidos da Vila inscrito no campeonato', 'Times inscritos (1)')
  end

  it 'recusa inscrever time de outro gestor' do
    post "/gestor/championships/#{championship.id}/enroll", params: { team_id: foreign_team.id }

    expect(championship.teams).to be_empty
    follow_redirect!
    expect(response.body).to include('pertence a outro gestor')
  end

  it 'remove a inscrição de time sem partidas e mantém a de time com partidas' do
    match = create(:match, championship:, home_team: own_team)
    idle = create(:team, manager:, name: 'Reserva FC')
    championship.championship_teams.create!(team: idle)

    delete "/gestor/championships/#{championship.id}/unenroll", params: { team_id: idle.id }
    delete "/gestor/championships/#{championship.id}/unenroll", params: { team_id: match.home_team_id }

    expect(championship.teams.reload).to contain_exactly(own_team, match.away_team)
  end

  it 'na nova partida a partir do campeonato, oferece só os times inscritos' do
    create(:match, championship:, home_team: own_team)
    create(:team, manager:, name: 'Fora da Copa')

    get '/gestor/matches/new', params: { match: { championship_id: championship.id } }

    expect(response.body).to include('Unidos da Vila')
    expect(response.body).not_to include('Fora da Copa')
  end

  it 'não aceita partida com time não inscrito' do
    other = create(:team, manager:)
    championship.championship_teams.create!(team: own_team)

    post '/gestor/matches', params: { match: { championship_id: championship.id, home_team_id: own_team.id,
                                               away_team_id: other.id, match_date: 2.days.from_now } }

    expect(championship.matches).to be_empty
    expect(response.body).to include('não está inscrito neste campeonato')
  end
end
