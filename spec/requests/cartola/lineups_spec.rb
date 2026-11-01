require 'rails_helper'

RSpec.describe 'Cartola lineups', type: :request do
  let(:user) { create(:user) }
  let(:squad) { create(:cartola_squad, user:) }

  def valid_players(cost: 5)
    { 'GOL' => 1, 'LAT' => 2, 'ZAG' => 2, 'MEI' => 3, 'ATA' => 3 }.flat_map do |position, count|
      create_list(:player, count, position:, cost:)
    end
  end

  def submit(players, formation: '4-3-3', round: 7)
    patch lineup_path(round:), params: { lineup: { formation:, player_ids: players.map(&:id) } }
  end

  context 'with a session' do
    before { sign_in(user) }

    it 'mostra a própria escalação' do
      lineup = create(:cartola_lineup, squad:, round: 7)

      get lineup_path(round: 7)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(lineup.players.first.name, '4-3-3')
    end

    it 'cria o squad no primeiro acesso' do
      expect { get lineup_path }.to change { Cartola::Squad.where(user:).count }.from(0).to(1)
      expect(response).to have_http_status(:ok)
    end

    it 'renderiza o formulário com formação e orçamento' do
      squad

      get edit_lineup_path(round: 7)

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.css('input[name="lineup[formation]"]').map { |input| input['value'] })
        .to match_array(Cartola::Lineup::FORMATIONS)
      expect(page.at_css('[data-role="budget-remaining"]').text).to include('100')
    end

    it 'salva uma escalação válida' do
      squad
      players = valid_players

      expect { submit(players) }.to change(Cartola::Lineup, :count).by(1)

      expect(response).to redirect_to(lineup_path(round: 7))
      expect(squad.lineups.find_by(round: 7).players).to match_array(players)
    end

    it 'recusa 10 jogadores' do
      squad

      expect { submit(valid_players.first(10)) }.not_to change(Cartola::Lineup, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'recusa 12 jogadores' do
      squad

      expect { submit(valid_players + [create(:player, position: 'ATA')]) }.not_to change(Cartola::Lineup, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'recusa formação inválida' do
      squad

      submit(valid_players, formation: '2-4-4')

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'recusa escalação acima de 100' do
      squad

      submit(valid_players(cost: 10))

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('orçamento')
    end

    it 'recebe 403 na escalação de outro usuário' do
      other = create(:cartola_lineup, round: 7)

      get lineup_path(round: 7, squad_id: other.squad_id)
      expect(response).to have_http_status(:forbidden)

      patch lineup_path(round: 7, squad_id: other.squad_id),
            params: { lineup: { formation: '4-3-3', player_ids: valid_players.map(&:id) } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'redireciona para o login sem sessão' do
    get lineup_path

    expect(response).to redirect_to(new_session_path)
  end
end
