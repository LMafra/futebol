require 'rails_helper'

RSpec.describe 'Cartola lineups', type: :request do
  let(:user) { create(:user) }
  let(:squad) { create(:cartola_squad, user:) }
  let!(:championship) { create(:championship) }
  let(:team) { create(:match, championship:).home_team }

  # The default limits: 1 goalkeeper, 2 defenders, 3 midfielders, 3 forwards.
  def valid_players(base_value: 5)
    { 'GOL' => 1, 'LAT' => 1, 'ZAG' => 1, 'MEI' => 3, 'ATA' => 3 }.flat_map do |position, count|
      create_list(:player, count, position:, base_value:, team:)
    end
  end

  def submit(players, formation: '4-3-3', round: 7, captain: players.first)
    patch lineup_path(round:),
          params: { lineup: { formation:, player_ids: players.map(&:id), captain_id: captain&.id } }
  end

  def balance = Cartola::Wallet.find_by!(user:, championship:).balance

  it 'redireciona /cartola para /esquadrao (301) mantendo a query string' do
    get '/cartola?round=3'

    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('/esquadrao?round=3')
  end

  context 'with a session' do
    before { sign_in(user) }

    it 'abre a escalação em /esquadrao' do
      create(:cartola_lineup, squad:, championship:, round: 7)

      get esquadrao_path(round: 7)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Rodada <span class="tabular-nums">7</span>')
    end

    it 'mostra a própria escalação' do
      lineup = create(:cartola_lineup, squad:, championship:, round: 7)

      get lineup_path(round: 7)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(lineup.players.first.name, '4-3-3', 'Esquadrão ·')
    end

    it 'cria o squad no primeiro acesso' do
      expect { get lineup_path }.to change { Cartola::Squad.where(user:).count }.from(0).to(1)
      expect(response).to have_http_status(:ok)
    end

    it 'renderiza o formulário com as formações, os limites do campeonato e o saldo' do
      squad

      get edit_lineup_path(round: 7)

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.css('input[name="lineup[formation]"]').map { |input| input['value'] })
        .to match_array(Cartola::Lineup::FORMATIONS)
      expect(page.at_css('[data-role="limits"]').text.squish).to include('Até 1 goleiro(s), 2 defensor(es)')
      expect(page.at_css('[data-role="budget-remaining"]').text).to include('100')
    end

    it 'lista só os jogadores dos times do campeonato e os já escalados' do
      player = create(:player, team:)
      away = create(:player, team: Core::Match.find_by!(home_team: team).away_team)
      outsider = create(:player)
      lineup = create(:cartola_lineup, squad:, championship:, round: 7)

      get edit_lineup_path(round: 7)

      listed = Nokogiri::HTML(response.body).css('input[type="checkbox"][name="lineup[player_ids][]"]')
                       .map { |input| input['value'] }
      expect(listed).to match_array([player, away, *lineup.players].map { |listed_player| listed_player.id.to_s })
      expect(listed).not_to include(outsider.id.to_s)
    end

    it 'ignora jogador de time fora do campeonato' do
      squad
      players = valid_players.first(8)

      submit(players + [create(:player, position: 'ATA')])

      expect(response).to redirect_to(lineup_path(round: 7))
      expect(squad.lineups.find_by!(championship:, round: 7).players).to match_array(players)
    end

    it 'salva uma escalação dentro dos limites e debita a carteira' do
      squad
      players = valid_players

      expect { submit(players) }.to change(Cartola::Lineup, :count).by(1)

      expect(response).to redirect_to(lineup_path(round: 7))
      expect(squad.lineups.find_by(championship:, round: 7).players).to match_array(players)
      expect(balance).to eq(100 - 45)
    end

    it 'cobra só os jogadores trocados ao editar' do
      players = valid_players
      submit(players)
      substitute = create(:player, position: 'ATA', base_value: 8, team:)

      submit(players.first(8) + [substitute])

      expect(response).to redirect_to(lineup_path(round: 7))
      expect(balance).to eq(100 - 45 - 8 + 5)
    end

    it 'exige um capitão entre os escalados' do
      squad
      players = valid_players

      expect { submit(players, captain: nil) }.not_to change(Cartola::Lineup, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Escolha um capitão entre os escalados')

      submit(players.first(8), captain: players.last)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'troca o capitão ao editar e o marca em campo' do
      squad
      players = valid_players
      submit(players)

      submit(players, captain: players.last)

      expect(response).to redirect_to(lineup_path(round: 7))
      lineup = squad.lineups.find_by!(championship:, round: 7)
      expect(lineup.lineup_players.where(captain: true).pluck(:player_id)).to eq([players.last.id])
      get lineup_path(round: 7)
      captain_card = Nokogiri::HTML(response.body).at_css('[data-role="captain"]').ancestors('li').first
      expect(captain_card.text).to include(players.last.name)
    end

    it 'marca o capitão no formulário de edição' do
      lineup = create(:cartola_lineup, squad:, championship:, round: 7)

      get edit_lineup_path(round: 7)

      checked = Nokogiri::HTML(response.body).at_css('input[name="lineup[captain_id]"][checked]')
      expect(checked['value']).to eq(lineup.captain_id.to_s)
    end

    it 'recusa mais jogadores numa posição do que o campeonato permite' do
      squad

      expect { submit(valid_players + [create(:player, position: 'GOL', team:)]) }
        .not_to change(Cartola::Lineup, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('o limite do campeonato é 1')
    end

    it 'recusa formação inválida' do
      squad

      submit(valid_players, formation: '2-4-4')

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'recusa escalação acima do saldo sem debitar' do
      squad

      submit(valid_players(base_value: 12))

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Saldo insuficiente')
      expect(balance).to eq(100)
    end

    it 'desfaz a escalação e devolve o valor à carteira' do
      submit(valid_players)

      expect { delete lineup_path(round: 7) }.to change(Cartola::Lineup, :count).by(-1)

      expect(response).to redirect_to(lineup_path(round: 7))
      expect(flash[:notice]).to include('C$ 45.00 devolvidos')
      expect(balance).to eq(100)
    end

    it 'recebe 403 na escalação de outro usuário' do
      other = create(:cartola_lineup, championship:, round: 7)

      get lineup_path(round: 7, squad_id: other.squad_id)
      expect(response).to have_http_status(:forbidden)

      patch lineup_path(round: 7, squad_id: other.squad_id),
            params: { lineup: { formation: '4-3-3', player_ids: valid_players.map(&:id) } }
      expect(response).to have_http_status(:forbidden)

      expect { delete lineup_path(round: 7, squad_id: other.squad_id) }.not_to change(Cartola::Lineup, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'redireciona para o login sem sessão' do
    get lineup_path

    expect(response).to redirect_to(new_session_path)
  end
end
