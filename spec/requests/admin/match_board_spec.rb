require 'rails_helper'

RSpec.describe 'Admin match page (tela única da partida)', type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 1.hour.ago) }
  let!(:keeper) { create(:player, team: match.home_team, position: 'GOL', name: 'Goleiro Casa') }
  let!(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Atacante Casa') }
  let!(:rival) { create(:player, team: match.away_team, position: 'ATA', name: 'Atacante Fora') }

  before do
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
    sign_in(admin)
  end

  def page = Nokogiri::HTML5(response.body)
  def line(player) = page.at_css("[data-role='player-line'][data-player-id='#{player.id}']")

  def record(player, stat, period: 'first_half', minute: '')
    post "/admin/matches/#{match.id}/record_event",
         params: { modal: 'lance', return_to: "/admin/matches/#{match.id}",
                   lance: { player_id: player.id, stat:, period:, minute: } }
  end

  def finalize(confirmation)
    post "/admin/matches/#{match.id}/finalize",
         params: { modal: 'finalize', return_to: "/admin/matches/#{match.id}",
                   finalize: { score_confirmation: confirmation } }
  end

  it 'mostra placar, abas por time, botões de lance (DE só para goleiro), linha do tempo e legenda' do
    get "/admin/matches/#{match.id}"

    expect(response).to have_http_status(:ok)
    expect(page.at_css('[data-role="scoreboard"] [data-role="score"]').text.squish).to eq('0 × 0')
    expect(page.css('[role="tab"]').map { _1.text.squish })
      .to eq(["Mandante · #{match.home_team.name}", "Visitante · #{match.away_team.name}"])
    expect(page.css('[data-role="side-home"] [data-role="player-line"]').map { _1['data-player-id'].to_i })
      .to eq([keeper.id, striker.id])
    expect(line(keeper).css('a[data-modal-open="modal-lance"]').map(&:text)).to include('+ Defesa')
    expect(line(striker).css('a[data-modal-open="modal-lance"]').map(&:text)).not_to include('+ Defesa')
    expect(page.at_css('[data-role="timeline"]').text).to include('Nenhum lance ainda.')
    expect(page.at_css('[data-role="legend"] dl[data-role="scout-legend"]')).to be_present
    expect(page.at_css('dialog#modal-lance')).to be_present
    expect(page.at_css('[data-role="no-scouts"]').text).to include('Lance os scouts antes de finalizar')
  end

  it 'abre o diálogo do lance pela URL, sem JavaScript, com o tempo sugerido' do
    get "/admin/matches/#{match.id}", params: { modal: 'lance', lance: { player_id: striker.id, stat: 'goals' } }

    dialog = page.at_css('dialog#modal-lance')
    expect(dialog['open']).not_to be_nil
    expect(dialog.at_css('h2').text).to eq('Gol · Atacante Casa')
    expect(dialog.at_css('input[name="lance[player_id]"]')['value']).to eq(striker.id.to_s)
    expect(dialog.at_css('select[name="lance[period]"] option[selected]')['value']).to eq('first_half')
  end

  it 'registra o lance com tempo e minuto, atualiza o placar e a linha do tempo' do
    expect { record(striker, 'goals', period: 'second_half', minute: '32') }
      .to change(Cartola::ScoutEvent.kept, :count).by(1)
      .and change(Core::AuditLog.where(action: 'cartola.scout_event_recorded'), :count).by(1)

    expect(response).to redirect_to("/admin/matches/#{match.id}")
    expect(match.reload).to have_attributes(home_score: 1, away_score: 0)
    follow_redirect!
    expect(response.body).to include('Lance registrado: Gol · Atacante Casa · 32&#39; · 2º tempo.')
    expect(page.css('[data-role="timeline-event"]').map { _1.text.squish })
      .to eq(["32' · 2º tempo Gol Atacante Casa #{match.home_team.name}"])
    expect(line(striker).text).to include('9.00 pts')
    expect(page.at_css('[data-role="derived-score"]').text.squish).to eq('Placar dos lances: 1 × 0')
  end

  it 'lance recusado volta ao diálogo com o erro e o que foi escolhido' do
    record(striker, 'saves', period: 'second_half')

    expect(response).to redirect_to("/admin/matches/#{match.id}?modal=lance")
    follow_redirect!
    dialog = page.at_css('dialog#modal-lance')
    expect(dialog['open']).not_to be_nil
    expect(dialog.at_css('[role="alert"]').text).to include('Defesas (DE) só contam para goleiros.')
    expect(dialog.at_css('select[name="lance[period]"] option[selected]')['value']).to eq('second_half')
    expect(Cartola::ScoutEvent.kept.where(match:)).to be_empty
  end

  it 'o "−" desfaz o último lance do jogador naquele scout' do
    record(striker, 'goals')

    expect { post "/admin/matches/#{match.id}/undo_event", params: { player_id: striker.id, stat: 'goals' } }
      .to change(Cartola::ScoutEvent.kept, :count).by(-1)

    expect(match.reload).to have_attributes(home_score: 0)
    follow_redirect!
    expect(response.body).to include('Desfeito: Gol · Atacante Casa · 1º tempo.')
  end

  it 'Jogou e Destaque sem lance, com um só destaque por partida' do
    post "/admin/matches/#{match.id}/participation", params: { player_id: striker.id, flags: { highlight: 'true' } }
    post "/admin/matches/#{match.id}/participation", params: { player_id: rival.id, flags: { highlight: 'true' } }
    post "/admin/matches/#{match.id}/participation", params: { player_id: keeper.id, flags: { played: 'true' } }

    scores = Cartola::PlayerScore.kept.where(match:).index_by(&:player_id)
    expect(scores.transform_values { [_1.played, _1.highlight] })
      .to eq(striker.id => [true, false], rival.id => [true, true], keeper.id => [true, false])

    post "/admin/matches/#{match.id}/participation", params: { player_id: keeper.id, flags: { played: 'false' } }
    expect(Cartola::PlayerScore.kept.where(match:, player: keeper)).to be_empty
  end

  describe 'Finalizar no diálogo' do
    before do
      record(striker, 'goals')
      record(striker, 'goals')
      record(rival, 'goals')
    end

    it 'confirmação diferente volta ao diálogo com o erro' do
      finalize('1x2')

      expect(response).to redirect_to("/admin/matches/#{match.id}?modal=finalize")
      follow_redirect!
      expect(page.at_css('dialog#modal-finalize [role="alert"]').text)
        .to include('não confere com o placar dos scouts (digite 2x1)')
      expect(match.reload).to be_live
    end

    it 'finaliza com o placar dos lances e enfileira a pontuação' do
      expect { finalize('2 x 1') }.to have_enqueued_job(ProcessMatchPointsJob).with(match.id, kind_of(String))

      expect(response).to redirect_to("/admin/matches/#{match.id}")
      expect(match.reload).to have_attributes(status: 'finished', home_score: 2, away_score: 1)
      follow_redirect!
      expect(response.body).to include('Partida finalizada em 2 × 1; pontuação enfileirada.')
    end
  end

  it 'fica só para leitura quando a partida foi pontuada' do
    match.update_columns(status: 'scored', home_score: 0, away_score: 0, scores_calculated_at: Time.current)

    get "/admin/matches/#{match.id}"

    expect(page.at_css('[data-role="readonly"]')).to be_present
    expect(page.at_css('dialog#modal-lance')).to be_nil
    expect(page.at_css('[data-role="finalize-bar"]')).to be_nil
  end

  it 'as páginas antigas redirecionam para a partida' do
    get '/admin/matchscouts', params: { match_id: match.id }
    expect(response).to redirect_to("/admin/matches/#{match.id}")

    get '/admin/matchfinalizer', params: { match_id: match.id }
    expect(response).to redirect_to("/admin/matches/#{match.id}?modal=finalize")
  end

  it 'não-admin recebe 403 e não registra lance' do
    sign_in(create(:user))

    record(striker, 'goals')

    expect(response).to have_http_status(:forbidden)
    expect(Cartola::ScoutEvent.count).to eq(0)
  end
end
