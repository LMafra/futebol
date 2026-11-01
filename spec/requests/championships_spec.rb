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
    standings = page.css('[data-role="standing-row"]').map do |row|
      [row.at_css('th').text.squish.delete_prefix(row.at_css('th span').text), row.css('td')[1].text]
    end
    expect(standings).to eq([%w[Alfa 3], %w[Beta 0]])
    expect(page.at_css('[data-role="simulate-championship"]')['href']).to eq(simulador_championship_path(championship))
  end

  it 'mostra uma rodada por vez na aba Partidas, abrindo na primeira rodada em aberto' do
    create(:match, championship:, home_team: home, away_team: away, status: 'finished', home_score: 1, away_score: 1,
                   match_date: 1.week.ago, round: 1)
    create(:match, championship:, home_team: away, away_team: home, round: 2)

    get public_championship_path(championship, tab: 'partidas')

    expect(page.at_css('#matches-title').text.squish).to eq('Partidas · Rodada 2')
    expect(page.css('[data-role="match-row"]').size).to eq(1)

    get public_championship_path(championship, tab: 'partidas', rodada: 1)

    expect(page.at_css('[data-role="match-row"]').text.squish).to include('Alfa', '1 × 1', 'Beta')
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
end
