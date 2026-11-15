require 'rails_helper'

RSpec.describe 'Deadline badges', type: :request do
  let(:user) { create(:user) }
  let(:championship) { create(:championship) }
  let(:pool) { create(:bolao_pool, championship:, owner: user) }

  before do
    pool.memberships.find_or_create_by!(user:)
    sign_in(user)
  end

  it 'mostra badge de prazo em partidas scheduled do bolão' do
    match = create(:match, championship:, status: 'scheduled', match_date: 2.hours.from_now, round: 1)
    get pool_bets_path(pool)

    expect(response).to have_http_status(:ok)
    badge = Nokogiri::HTML(response.body).at_css(%([data-role="match"][id="bet_match_#{match.id}"] [data-role="match-deadline-badge"]))
    expect(badge).to be_present
    expect(badge['data-countdown-deadline-value']).to eq(match.match_date.iso8601)
  end

  it 'alerta palpites em aberto que fecham hoje na área pessoal' do
    create(:match, championship:, status: 'scheduled', match_date: 3.hours.from_now, round: 1)

    get users_dashboard_path

    expect(response).to have_http_status(:ok)
    alert = Nokogiri::HTML(response.body).at_css('[data-role="open-bets-today-alert"]')
    expect(alert.text).to include('palpites em aberto que fecham hoje')
  end

  it 'mostra badge de fechamento e bloqueia update após T-15 na escalação' do
    kickoff = 10.minutes.from_now
    create(:match, championship:, status: 'scheduled', match_date: kickoff, round: 1)

    get esquadrao_path, params: { championship_id: championship.id, round: 1 }
    expect(response.body).to include('data-role="lineup-deadline-badge"')
    expect(response.body).to match(/Escalação fecha|Escalação fechada/)

    patch lineup_path(championship_id: championship.id, round: 1),
          params: { lineup: { formation: '4-3-3', player_ids: [], captain_id: '' } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Escalação fechada')
  end
end
