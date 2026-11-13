require 'rails_helper'

RSpec.describe 'Admin MatchScouts page', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 1.hour.ago) }
  let!(:keeper) { create(:player, team: match.home_team, position: 'GOL', name: 'Goleiro Casa') }
  let!(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Atacante Casa') }
  let!(:rival) { create(:player, team: match.away_team, position: 'ATA', name: 'Atacante Fora') }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
    sign_in(admin)
  end

  def page_html = Nokogiri::HTML(response.body)

  def record(highlight: nil, **rows)
    scouts = rows.to_h { |player, values| [player.id.to_s, { team_id: player.team_id, played: '0', **values }] }
    post '/admin/matchscouts/record', params: { match_id: match.id, scouts:, highlight: highlight&.id.to_s }
  end

  it 'mostra as duas tabelas, com DE só para goleiros e limites nos contadores' do
    get '/admin/matchscouts', params: { match_id: match.id }

    expect(response).to have_http_status(:ok)
    page = page_html
    expect(page.css('[role="tab"]').map { |tab| tab.text.squish })
      .to eq(["Mandante · #{match.home_team.name}", "Visitante · #{match.away_team.name}"])
    expect([page.at_css('[data-role="team-home"]'), page.at_css('[data-role="team-away"]')].map { _1.key?('hidden') })
      .to eq([false, true])
    headers = page.css('[data-role="team-home"] thead th')
    expect(headers.map { |th| th.at_css('abbr')&.text || th.text }).to eq(%w[Nome G A DP DE CA CV GC SG Jogou Destaque
                                                                             Pts])
    expect(headers[1].at_css('abbr')['title']).to eq('Gol')
    expect(headers[1].at_css('span.sm\:hidden').text).to eq('Gol')
    legend = page.at_css('dl[data-role="scout-legend"]')
    expect(legend['aria-label']).to eq('Legenda dos scouts')
    expect(legend.css('dt').map(&:text)).to eq(%w[G A SG DP DE CA CV GC])
    expect(legend.css('dd').map(&:text)).to include('Jogo sem sofrer gols', 'Gol contra')
    expect(page.css('[data-role="team-home"] tbody tr').map { |tr| tr.at_css('td').text.squish })
      .to eq(['Goleiro Casa GOL', 'Atacante Casa ATA'])
    expect(page.at_css("input[name='scouts[#{keeper.id}][saves]']")['disabled']).to be_nil
    expect(page.at_css("input[name='scouts[#{striker.id}][saves]']")['disabled']).to be_present
    yellow = page.at_css("input[name='scouts[#{striker.id}][yellow_cards]']")
    expect([yellow['min'], yellow['max']]).to eq(%w[0 2])
    expect(page.at_css("input[name='scouts[#{striker.id}][penalty_saves]']")['max']).to eq('3')
    expect(page.at_css('[data-controller="scouts"]')['data-scouts-weights-value']).to include('"goals":8.0')
  end

  it 'salva os scouts, atualiza o placar e mostra os pontos' do
    record(striker => { played: '1', goals: '1' }, rival => { played: '1' }, highlight: striker)

    expect(response).to redirect_to("/admin/matchscouts?match_id=#{match.id}")
    expect(match.reload).to have_attributes(home_score: 1, away_score: 0)
    follow_redirect!
    expect(response.body).to include('Scouts salvos · placar 1 × 0.')
    expect(page_html.at_css("tr[data-player-id='#{striker.id}'] [data-role='points']").text).to eq('9.00')
    expect(page_html.at_css("input[name='highlight'][value='#{striker.id}']")['checked']).to be_present
  end

  it 'recusa scouts inválidos com 422, mantendo o que foi digitado' do
    record(striker => { played: '1', saves: '2' })

    expect(response).to have_http_status(:unprocessable_content)
    expect(page_html.at_css('[data-role="form-errors"]').text).to include('defesas (DE) só contam para goleiros')
    expect(page_html.at_css("input[name='scouts[#{striker.id}][played]'][type=checkbox]")['checked']).to be_present
    expect(Cartola::PlayerScore.kept.where(match:)).to be_empty
  end

  it 'fica só para leitura quando a partida foi pontuada' do
    match.update_columns(status: 'scored', home_score: 0, away_score: 0, scores_calculated_at: Time.current)

    get '/admin/matchscouts', params: { match_id: match.id }

    expect(page_html.at_css('[data-role="readonly"]')).to be_present
    expect(page_html.css('form input[type=number]').all? { |input| input['disabled'] }).to be(true)
    expect(page_html.at_css('input[type=submit][value="Salvar scouts"]')).to be_nil
  end

  it 'não-admin recebe 403' do
    sign_in(create(:user))

    record(striker => { played: '1' })

    expect(response).to have_http_status(:forbidden)
    expect(Cartola::PlayerScore.count).to eq(0)
  end
end
