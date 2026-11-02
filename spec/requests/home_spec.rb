require 'rails_helper'

RSpec.describe 'Public home', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:public_championship) { create(:championship, name: 'Copa Aberta') }
  def page = Nokogiri::HTML(response.body)

  def score_bet(user, championship, points)
    prediction = create(:bolao_prediction, user:, match: create(:match, championship:),
                                           pool: create(:bolao_pool, championship:))
    create(:bolao_prediction_score, prediction:, points:)
  end

  it 'abre sem login, com hero, contadores, módulos, jogos de hoje, campeonatos, atletas e como funciona' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(page.at_css('h1').text).to eq('Craquefy')
    expect(page.at_css('[data-role="hero"]').text.squish)
      .to include('O campeonato do seu jeito', 'Bolão · Esquadrão · Simulador')
    %w[counters matches-today top-players how-it-works].each do |role|
      expect(page.at_css("[data-role='#{role}']")).to be_present, role
    end
    expect(page.css('[data-role="module-card"] h3').map(&:text)).to eq(%w[Bolão Esquadrão Simulador])
    expect(page.at_css('footer').text.squish).to include('© ', 'Craquefy', 'GitHub', 'Documentação', 'Licença MIT')
  end

  it 'mostra "Entrar" e "Criar conta" para visitantes e os atalhos dos módulos para quem está logado' do
    get root_path
    actions = page.at_css('[data-role="hero-actions"]')
    expect(actions.css('a').map { |link| [link.text, link['href']] })
      .to eq([['Entrar', '/entrar'], ['Criar conta', '/signup']])
    expect(actions.at_css('a[href="/entrar"]')['class']).to include('bg-cartola')

    sign_in(create(:user))
    get root_path
    expect(page.at_css('[data-role="hero-actions"]').css('a').map(&:text))
      .to eq(['Meus bolões', 'Meu esquadrão', 'Simulador'])
  end

  it 'lista só os campeonatos públicos, com contadores gerais, Top 3 do Bolão e do Esquadrão e link para o ranking' do
    create(:match, championship: public_championship)
    private_championship = create(:championship, name: 'Copa Secreta', private: true)
    create(:match, championship: private_championship)
    create(:player)
    %w[Ana Bia Caio Davi].each_with_index do |name, points|
      fan = create(:user, name: "#{name} Lima", public_profile_consented_at: 1.day.ago)
      score_bet(fan, public_championship, points)
    end

    get root_path

    cards = page.css('[data-role="championship-card"]')
    expect(cards.map { |card| card.at_css('h3').text.squish }).to eq(['Copa Aberta'])
    expect(response.body).not_to include('Copa Secreta')
    expect(page.at_css('[data-role="counter-championships"] dt').text).to eq('Campeonatos')
    expect(page.at_css('[data-role="counter-championships"] dd').text).to eq('2')
    expect(page.at_css('[data-role="counter-matches"] dd').text).to eq('6')
    expect(page.at_css('main').text).not_to match(/campeonatos? públic|privad/i)
    expect(cards.first.css('[data-role="top-bolao"] [data-role="leaderboard-row"]').map { |row| row.text.squish })
      .to eq(['1 Davi L. 3', '2 Caio L. 2', '3 Bia L. 1'])
    expect(cards.first.at_css('[data-role="top-esquadrao"]').text).to include('Sem escalações pontuadas.')
    expect(cards.first.at_css('a[href$="tab=bolao"]').text).to eq('Ver ranking completo')
  end

  it 'abre o card com a classificação (líderes dos jogos encerrados) antes do Top 3 do Bolão e do Esquadrão' do
    teams = %w[Alfa Beta Gama Delta Ômega].map { |name| create(:team, name:) }
    [[0, 1, 3, 0], [2, 3, 1, 1], [0, 2, 2, 1], [4, 1, 1, 0]].each do |home, away, home_score, away_score|
      create(:match, championship: public_championship, home_team: teams[home], away_team: teams[away],
                     status: 'finished', home_score:, away_score:)
    end
    create(:match, championship: public_championship, home_team: teams[1], away_team: teams[0],
                   status: 'live', home_score: 9, away_score: 0)
    empty_championship = create(:championship, name: 'Copa Nova')
    create(:match, championship: empty_championship)

    get root_path

    card = page.css('[data-role="championship-card"]').find { |node| node.at_css('h3').text.squish == 'Copa Aberta' }
    blocks = card.css('[data-role="standings-leaders"], [data-role="top-bolao"], [data-role="top-esquadrao"]')
    expect(blocks.map { |block| block['data-role'] }).to eq(%w[standings-leaders top-bolao top-esquadrao])
    leaders = card.at_css('[data-role="standings-leaders"]')
    expect(leaders.css('[data-role="leaderboard-row"]').map { |row| row.text.squish })
      .to eq(['1 Alfa 6', '2 Ômega 3', '3 Delta 1', '4 Gama 1'])
    expect(leaders.at_css('a', text: 'Tabela completa')['href']).to eq(public_championship_path(public_championship))
    new_card = page.css('[data-role="championship-card"]').find { |node| node.at_css('h3').text.squish == 'Copa Nova' }
    expect(new_card.at_css('[data-role="standings-leaders"]').text).to include('Nenhum jogo encerrado ainda.')
  end

  it 'leva ao Simulador pelo card de cada campeonato, não pelo cabeçalho' do
    public_championship

    get root_path

    simulate = page.at_css('[data-role="championship-card"] [data-role="simulate-championship"]')
    expect(simulate.text).to eq('Simular')
    expect(simulate['href']).to eq(simulador_championship_path(public_championship))
    expect(simulate['aria-label']).to eq('Simular Copa Aberta')
    expect(page.at_css('nav[aria-label="Principal"]').text).not_to include('Simulador')
  end

  it 'guia a rolagem da home seção a seção (scroll snap por proximidade), só na home' do
    get root_path

    sections = page.at_css('[data-role="home-sections"]')
    expect(sections['data-controller']).to eq('scroll-snap')
    expect(sections['class'].split).to include('*:snap-start')
    expect(page.css('body > header, body > footer').map { |node| node['class'].split.first })
      .to eq(%w[snap-start snap-end])

    get login_path
    expect(page.at_css('[data-controller="scroll-snap"]')).to be_nil
  end

  it 'mostra os jogos de hoje dos campeonatos públicos' do
    today = create(:match, championship: public_championship, match_date: Time.current.change(hour: 21))
    create(:match, championship: public_championship, match_date: 3.days.from_now)
    create(:match, championship: create(:championship, private: true), match_date: Time.current.change(hour: 21))

    get root_path

    expect(page.css('[data-role="today-match"]').size).to eq(1)
    expect(page.at_css('[data-role="today-match"]').text).to include(today.home_team.name, '21:00')
  end

  it 'conta "hoje" no horário de Brasília, mesmo quando já é o dia seguinte em UTC' do
    brasilia = Time.find_zone!('America/Sao_Paulo')
    tonight = create(:match, championship: public_championship, match_date: brasilia.local(2026, 11, 1, 21))
    create(:match, championship: public_championship, match_date: brasilia.local(2026, 11, 2, 10))

    travel_to(brasilia.local(2026, 11, 1, 22, 30)) { get root_path }

    expect(page.css('[data-role="today-match"]').size).to eq(1)
    expect(page.at_css('[data-role="today-match"]').text).to include(tonight.home_team.name, '21:00')
  end

  it 'põe os jogos de hoje numa faixa horizontal única e sem fim, por horário, com o campeonato em cada card' do
    varzea = create(:championship, name: 'Copa da Várzea')
    create(:match, championship: varzea, match_date: Time.current.change(hour: 10))
    create(:match, championship: public_championship, match_date: Time.current.change(hour: 15))
    create(:match, championship: varzea, match_date: Time.current.change(hour: 21))

    get root_path

    today = page.at_css('[data-role="matches-today"]')
    expect(today['data-controller']).to eq('scroller')
    expect(today.css('[data-role="today-championship"]')).to be_empty
    expect(today.css('ul').size).to eq(1)
    expect(today.at_css('ul')['class'].split).to include('overflow-x-auto', 'snap-x')
    cards = today.css('[data-role="today-match"]')
    expect(cards.map { |card| card.at_css('[data-role="today-match-championship"]').text })
      .to eq(['Copa da Várzea', public_championship.name, 'Copa da Várzea'])
    expect(cards.map { |card| card.text[/\d{2}:\d{2}/] }).to eq(%w[10:00 15:00 21:00])
    expect(cards.first.at_css('a')['href']).to eq(public_championship_path(varzea))
    expect(today.at_css('[data-role="today-count"]').text).to eq('3 jogos')
    expect(today.at_css('ul')['data-action']).to eq('scroll->scroller#scrolled')
    expect(today.css('button[data-action^="scroller#"]').map { |button| [button['aria-label'], button['disabled']] })
      .to eq([['Jogos anteriores', nil], ['Próximos jogos', nil]])
  end

  it 'mostra o top de atletas com J, G, A e Pts' do
    match = create(:match, championship: public_championship)
    star = create(:player, name: 'Craque')
    create(:cartola_player_score, player: star, match:, goals: 2, assists: 1, played: true, points: 21)
    create(:cartola_player_score, match:, played: true, points: 3)

    get root_path

    rows = page.css('[data-role="top-players"] [data-role="leaderboard-row"]').map { |row| row.text.squish }
    expect(rows.first).to eq("1 Craque #{star.team.short_name} 1 2 1 21.00")
    expect(rows.size).to eq(2)
  end

  it 'não expõe e-mails nem nomes sem consentimento' do
    score_bet(create(:user, name: 'Zeca Anônimo', email_address: 'zeca@exemplo.test'), public_championship, 10)

    get root_path

    expect(response.body).not_to include('zeca@exemplo.test', 'Zeca')
    expect(page.at_css('[data-role="top-bolao"]').text).to include('Participante')
  end

  it 'carrega os campeonatos em lote, sem N+1' do
    3.times { |index| score_bet(create(:user), create(:championship, name: "Copa #{index}"), 5) }

    expect { get root_path }.not_to raise_error
    expect(page.css('[data-role="championship-card"]').size).to eq(3)
  end
end
