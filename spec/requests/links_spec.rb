require 'rails_helper'

RSpec.describe 'Links e botões com rótulo de destino (TICKET-0106)', type: :request do
  include ActiveJob::TestHelper

  def page = Nokogiri::HTML(response.body)

  it 'os ícones de linha do Gestor dizem verbo e registro' do
    manager = create(:user, :manager)
    team = create(:team, name: 'Real Paraisópolis')
    create(:match, championship: create(:championship, manager:), home_team: team)
    sign_in(manager)

    get '/gestor/teams'

    labels = page.css("tr#core_team_#{team.id} [data-role='admin-table-action']").map { _1['aria-label'] }
    expect(labels).to include('Abrir Real Paraisópolis', 'Editar Real Paraisópolis')
  end

  it 'os ícones padrão do Admin dizem verbo e registro' do
    sign_in(create(:user, :admin))
    team = create(:team, name: 'Juventude do Morro')

    get '/admin/teams'

    labels = page.css("tr#core_team_#{team.id} [data-role='admin-table-action']").map { _1['aria-label'] }
    expect(labels.first).to eq('Abrir Juventude do Morro')
    expect(labels).to all(end_with('Juventude do Morro'))
  end

  it 'o painel vazio do Gestor oferece "Criar campeonato"' do
    sign_in(create(:user, :manager))

    get '/gestor'

    links = page.css('a').map { _1.text.strip }
    expect(links).to include('Criar campeonato')
    expect(links).not_to include('Crie o primeiro')
  end

  it 'o filtro dos rankings do Esquadrão diz o que faz' do
    user = create(:user)
    create_list(:championship, 2)
    sign_in(user)

    get esquadrao_rankings_path

    form = page.at_css("main form[action='#{esquadrao_rankings_path}']")
    expect(form.at_css('button[type="submit"]').text.strip).to eq('Mostrar ranking')
  end

  it 'o e-mail de redefinição usa um link com destino claro' do
    user = create(:user)
    perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }

    html = Nokogiri::HTML(ActionMailer::Base.deliveries.last.html_part.body.to_s)
    expect(html.css('a').map { _1.text.strip }).to eq(['Redefinir minha senha'])
  end

  it 'links de texto do público ficam sublinhados em repouso' do
    create(:championship, name: 'Copa da Vila')

    get root_path

    title_links = page.css('[data-role="championship-card"] h3 a')
    expect(title_links.map(&:text)).to include('Copa da Vila')
    expect((title_links + page.css('footer nav a')).map { _1['class'].split }).to all(include('underline'))
  end
end
