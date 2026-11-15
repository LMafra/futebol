require 'rails_helper'

RSpec.describe 'Busca por nome nas listagens do Admin e do Gestor', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:own_championship) { create(:championship, manager:) }
  let(:foreign_championship) { create(:championship) }
  let!(:own_team) { create(:team, name: 'Azulão do Gestor') }
  let!(:foreign_team) { create(:team, name: 'Azul Celeste Alheio') }

  before do
    create(:match, championship: own_championship, home_team: own_team)
    create(:match, championship: foreign_championship, home_team: foreign_team)
  end

  def suggestions = response.parsed_body

  it 'o filtro de nome é um campo simples, sem contém/igual/começa/termina, com autocomplete' do
    sign_in(manager)

    get '/gestor/teams'

    page = Nokogiri::HTML(response.body)
    field = page.at_css('form.filters-form input[name="q[name_cont]"]')
    expect(field.attributes.transform_values(&:value))
      .to include('data-controller' => 'autocomplete', 'autocomplete' => 'off')
    expect(page.at_css('form.filters-form label[for="q_name_cont"]').text).to eq('Nome')
    expect(page.css('form.filters-form select[name*="name"]')).to be_empty
  end

  it 'sugere só os times que o gestor pode listar' do
    sign_in(manager)

    get '/gestor/teams/autocomplete', params: { q: 'azu' }

    expect(response).to have_http_status(:ok)
    expect(suggestions).to eq(['Azulão do Gestor'])
  end

  it 'o admin recebe sugestões de todos, em ordem alfabética' do
    sign_in(create(:user, :admin))

    get '/admin/teams/autocomplete', params: { q: 'azu' }

    expect(suggestions).to eq(['Azul Celeste Alheio', 'Azulão do Gestor'])
  end

  it 'não sugere nada com menos de 2 letras e trata % como texto' do
    sign_in(create(:user, :admin))

    get '/admin/teams/autocomplete', params: { q: 'a' }
    expect(suggestions).to eq([])

    get '/admin/teams/autocomplete', params: { q: '%%' }
    expect(suggestions).to eq([])
  end

  it 'usuário comum não acessa as sugestões' do
    sign_in(create(:user))

    get '/gestor/teams/autocomplete', params: { q: 'azu' }

    expect(response).to have_http_status(:forbidden)
  end

  it 'rodada e temporada viram selects simples' do
    sign_in(manager)

    get '/gestor/matches'
    page = Nokogiri::HTML(response.body)
    expect(page.css('select[name="q[round_eq]"] option').map(&:text)).to include('1', '38')

    get '/gestor/championships'
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('select[name="q[season_eq]"]')).to be_present
  end
end
