require 'rails_helper'

RSpec.describe 'Public championship page', type: :request do
  let(:championship) { create(:championship, name: 'Copa Teste', season: 2026) }
  let(:home) { create(:team, name: 'Alfa') }
  let(:away) { create(:team, name: 'Beta') }

  def page = Nokogiri::HTML(response.body)

  it 'abre sem login na aba Times, com a classificação das partidas encerradas e as 4 abas' do
    create(:match, championship:, home_team: home, away_team: away, status: 'finished', home_score: 2, away_score: 0,
                   match_date: 2.days.ago, round: 1)
    create(:match, championship:, home_team: away, away_team: home, round: 2)

    get public_championship_path(championship)

    expect(response).to have_http_status(:ok)
    expect(page.at_css('h1').text).to eq('Copa Teste')
    expect(page.css('[data-role="championship-tab"]').map(&:text)).to eq(%w[Times Partidas Bolão Esquadrão])
    expect(page.at_css('[aria-current="page"]').text).to eq('Times')
    expect(page.css('[role="tab"], [role="tablist"], [aria-selected]')).to be_empty
    standings = page.css('[data-role="standing-row"]').map do |row|
      [row.at_css('th').text.squish.delete_prefix(row.at_css('th span').text), row.css('td')[1].text]
    end
    expect(standings).to eq([%w[Alfa 3], %w[Beta 0]])
    expect(page.at_css('[data-role="simulate-championship"]')['href']).to eq(simulador_championship_path(championship))
  end

  it 'agrupa a aba Partidas por rodada, com a primeira rodada em aberto aberta e link para a página ao vivo' do
    create(:match, championship:, home_team: home, away_team: away, status: 'finished', home_score: 1, away_score: 1,
                   match_date: 1.week.ago, round: 1)
    live = create(:match, championship:, home_team: away, away_team: home, status: 'live', home_score: 0,
                          away_score: 0, round: 2)
    create(:match, championship:, home_team: home, away_team: away, round: 3)

    get public_championship_path(championship, tab: 'partidas')

    groups = page.css('#public-matches [data-role="collection-group"]')
    expect(groups.map { |group| group.at_css('summary span').text }).to eq(['Rodada 1', 'Rodada 2', 'Rodada 3'])
    expect(groups.map { |group| group.key?('open') }).to eq([false, true, false])
    row = groups[1].at_css('[data-role="match-row"]')
    expect(row['href']).to eq(public_match_path(live))
    expect(row['aria-label']).to eq('Beta × Alfa: acompanhar ao vivo')
    expect(row.at_css('[data-role="live-chip"]').text).to eq('Ao vivo')

    get public_championship_path(championship, tab: 'partidas', rodada: 1)

    open = page.at_css('#public-matches [data-role="collection-group"][open]')
    expect(open.at_css('summary span').text).to eq('Rodada 1')
    expect(open.at_css('[data-role="match-row"]').text.squish).to include('Alfa', '1 × 1', 'Beta', 'Encerrado')
    expect(open.at_css('[data-role="match-row"]')['aria-label']).to eq('Alfa × Beta: abrir a partida')
  end

  it 'abre a última rodada quando todas estão encerradas e lista as partidas sem rodada' do
    create(:match, championship:, home_team: home, away_team: away, status: 'finished', round: 1)
    create(:match, championship:, home_team: away, away_team: home, status: 'finished', round: 2)
    create(:match, championship:, home_team: home, away_team: away, round: nil)

    get public_championship_path(championship, tab: 'partidas', rodada: 9)

    groups = page.css('#public-matches [data-role="collection-group"]')
    expect(groups.map { |group| [group.at_css('summary span').text, group.key?('open')] })
      .to eq([['Rodada 1', false], ['Rodada 2', true], ['Sem rodada', false]])
  end

  it 'lista os rankings do Bolão e do Esquadrão sem e-mails, com o nome público' do
    user = create(:user, name: 'Ana Souza', email_address: 'ana@exemplo.test', public_profile_consented_at: 1.day.ago)
    prediction = create(:bolao_prediction, user:, match: create(:match, championship:),
                                           pool: create(:bolao_pool, championship:))
    create(:bolao_prediction_score, prediction:, points: 10)
    create(:cartola_lineup, squad: create(:cartola_squad, user:), championship:)

    get public_championship_path(championship, tab: 'bolao')
    expect(page.css('[data-role="leaderboard-row"]').map { |row| row.text.squish }).to eq(['1 Ana S. 10'])
    expect(response.body).not_to include('ana@exemplo.test', 'Ana Souza')

    get public_championship_path(championship, tab: 'esquadrao')
    expect(page.css('[data-role="leaderboard-row"]').map { |row| row.text.squish }).to eq(['1 Ana S. 0.00'])
    expect(response.body).not_to include('ana@exemplo.test', 'Ana Souza')
  end

  it 'cai na aba Times com uma aba desconhecida' do
    get public_championship_path(championship, tab: 'outra')

    expect(page.at_css('[aria-current="page"]').text).to eq('Times')
  end

  it 'dá 404 para campeonato privado, mesmo com login' do
    private_championship = create(:championship, private: true)

    get public_championship_path(private_championship)
    expect(response).to have_http_status(:not_found)

    sign_in(create(:user, :admin))
    get public_championship_path(private_championship)
    expect(response).to have_http_status(:not_found)
  end

  it 'dá 404 para rascunho e não o conta na home (TICKET-0092)' do
    draft = create(:championship, name: 'Copa em Rascunho', status: 'draft')

    get public_championship_path(draft)
    expect(response).to have_http_status(:not_found)

    get root_path
    expect(response.body).not_to include('Copa em Rascunho')
  end
end
