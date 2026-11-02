require 'rails_helper'

RSpec.describe 'Public home', type: :request do
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

  it 'mostra os jogos de hoje dos campeonatos públicos' do
    today = create(:match, championship: public_championship, match_date: Time.current.change(hour: 21))
    create(:match, championship: public_championship, match_date: 3.days.from_now)
    create(:match, championship: create(:championship, private: true), match_date: Time.current.change(hour: 21))

    get root_path

    expect(page.css('[data-role="today-match"]').size).to eq(1)
    expect(page.at_css('[data-role="today-match"]').text).to include(today.home_team.name, '21:00')
  end

  it 'agrupa os jogos de hoje por campeonato, com link para cada um' do
    varzea = create(:championship, name: 'Copa da Várzea')
    create_list(:match, 2, championship: varzea, match_date: Time.current.change(hour: 10))
    create(:match, championship: public_championship, match_date: Time.current.change(hour: 21))

    get root_path

    groups = page.css('[data-role="today-championship"]')
    expect(groups.map { |group| group.at_css('h3 a').text }).to eq(['Copa da Várzea', public_championship.name])
    expect(groups.first.at_css('h3 a')['href']).to eq(public_championship_path(varzea))
    expect(groups.map { |group| group.css('[data-role="today-match"]').size }).to eq([2, 1])
    expect(groups.first.at_css('h3').text).to include('2 jogos')
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
