require 'rails_helper'

RSpec.describe 'Simulador', type: :request do
  let(:championship) { create(:championship) }
  let(:teams) { %w[Atlético Botafogo Cruzeiro Fortaleza].map { |name| create(:team, name:) } }
  let!(:played) do
    create(:match, championship:, home_team: teams[0], away_team: teams[1], status: 'scored', round: 1,
                   home_score: 2, away_score: 0, match_date: 2.weeks.ago, scores_calculated_at: 1.week.ago,
                   scoring_token: SecureRandom.uuid)
  end
  let!(:open_match) do
    create(:match, championship:, home_team: teams[1], away_team: teams[2], status: 'scheduled', round: 2)
  end
  let!(:live_match) do
    create(:match, championship:, home_team: teams[3], away_team: teams[0], status: 'live', round: 2,
                   home_score: 1, away_score: 0, match_date: 1.hour.ago)
  end

  def page = Nokogiri::HTML(response.body)

  def team_name(row) = row.at_css('th').xpath('text()').text.squish

  def table_names(scope) = page.css("#{scope} [data-role='standing-row']").map { |row| team_name(row) }

  def preview(guesses, path: simulador_preview_path(championship))
    post path, params: { guesses: }
  end

  describe 'GET /simulador/:championship_id' do
    it 'marca o jogo ao vivo com um chip legível e campos de 48px (TICKET-0082)' do
      get simulador_championship_path(championship)

      chip = page.at_css("[data-match-id='#{live_match.id}'] [data-role='live-chip']")
      expect(chip['class'].split).to include('bg-cartola', 'text-ink')
      expect(page.at_css("input[name='guesses[#{live_match.id}][home]']")['class'].split).to include('min-h-12')
    end

    it 'é público: mostra a tabela atual e o formulário dos jogos em aberto (200)' do
      get simulador_championship_path(championship)

      expect(response).to have_http_status(:ok)
      expect(page.at_css('#table-title').text).to eq('Tabela atual')
      expect(table_names('[data-role="real-table"]')).to eq(%w[Atlético Cruzeiro Fortaleza Botafogo])
      expect(page.at_css('[data-role="reset-simulation"]')).to be_nil
      expect(page.css('[data-role="open-match"]').map { |li| li['data-match-id'].to_i })
        .to eq([live_match.id, open_match.id])
      expect(page.at_css("input[name='guesses[#{live_match.id}][home]']")['value']).to eq('1')
      expect(page.at_css("input[name='guesses[#{played.id}][home]']")).to be_nil
    end

    it 'põe todas as rodadas no carrossel, abrindo na primeira com jogo em aberto' do
      create(:match, championship:, home_team: teams[2], away_team: teams[3], status: 'scheduled', round: 3)

      get simulador_championship_path(championship)

      form = page.at_css('form[data-controller="rounds"]')
      expect(form['data-rounds-index-value']).to eq('1')
      expect(form.css('[data-rounds-target="round"]').map { |round| [round['data-round-label'], round['data-role']] })
        .to eq([['Rodada 1', 'closed-round'], ['Rodada 2', 'open-round'], ['Rodada 3', 'open-round']])
      expect(form.at_css('[data-role="rounds-nav"]')['hidden']).not_to be_nil
      expect(form.css('[data-rounds-target="nav"] button').map(&:text).map(&:squish)).to eq(%w[Anterior Próxima])
    end

    it 'mostra o resultado das rodadas encerradas, sem campos de placar' do
      get simulador_championship_path(championship)

      closed = page.at_css('[data-role="closed-round"]')
      expect(closed.at_css('legend').text).to eq('Rodada 1 · encerrada')
      expect(closed.css('input')).to be_empty
      result = closed.at_css("[data-role='closed-match'][data-match-id='#{played.id}']")
      expect(result.text.squish).to include('Atlético', '2×0', 'Placar final: 2 a 0', 'Botafogo')
    end

    it 'mostra as rodadas encerradas mesmo sem jogos em aberto, sem o botão de projetar' do
      [open_match, live_match].each(&:destroy!)

      get simulador_championship_path(championship)

      expect(page.text).to include('Todos os jogos deste campeonato já foram encerrados.')
      expect(page.css('[data-role="closed-round"]').size).to eq(1)
      expect(page.at_css('button[type="submit"]')).to be_nil
    end

    it 'leva para a página do campeonato e para a lista de campeonatos' do
      get simulador_championship_path(championship)

      links = page.at_css('[data-role="simulator-nav"]').css('a').to_h { |link| [link.text, link['href']] }
      expect(links).to eq('Ver campeonato' => public_championship_path(championship),
                          'Outros campeonatos' => simulador_path)
      expect(page.at_css('select#championship_id')).to be_nil
    end

    it 'responde 304 quando nada mudou (ETag)' do
      get simulador_championship_path(championship)
      etag = response.headers['ETag']

      get simulador_championship_path(championship), headers: { 'If-None-Match' => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it 'responde 404 para campeonato inexistente' do
      get simulador_championship_path(0)

      expect(response).to have_http_status(:not_found)
    end

    it 'esconde campeonato privado de visitantes (404), mas não de usuários logados' do
      championship.update!(private: true)

      get simulador_championship_path(championship)
      expect(response).to have_http_status(:not_found)

      sign_in(create(:user))
      get simulador_championship_path(championship)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /simulador' do
    it 'lista os campeonatos públicos para escolher, sem login e sem abrir nenhum direto' do
      private_championship = create(:championship, name: 'Copa Secreta', private: true)

      get simulador_path

      expect(response).to have_http_status(:ok)
      cards = page.css('[data-role="simulator-championship"]')
      expect(cards.map { |card| card['data-championship-id'].to_i }).to eq([championship.id])
      expect(cards.first.at_css('a')['href']).to eq(simulador_championship_path(championship))
      expect(page.css('[data-role="open-match"]')).to be_empty
      expect(response.body).not_to include(private_championship.name)
    end

    it 'mostra também os privados para quem está logado' do
      private_championship = create(:championship, name: 'Copa Secreta', private: true)
      sign_in(create(:user))

      get simulador_path

      expect(page.css('[data-role="simulator-championship"]').map { |card| card['data-championship-id'].to_i })
        .to contain_exactly(championship.id, private_championship.id)
      expect(page.at_css('main').text).not_to match(/campeonatos? públic|privad/i)
    end
  end

  describe 'POST /simulador/:championship_id/preview' do
    it 'volta na rodada em que o visitante estava, ou na primeira com erro' do
      round_three = create(:match, championship:, home_team: teams[2], away_team: teams[3], status: 'scheduled',
                                   round: 3)

      post simulador_preview_path(championship), params: { round_index: '0', guesses: {} }
      expect(page.at_css('form[data-controller="rounds"]')['data-rounds-index-value']).to eq('0')

      post simulador_preview_path(championship), params: { round_index: '1',
                                                           guesses: { round_three.id => { home: '-1', away: '0' } } }
      expect(page.at_css('form[data-controller="rounds"]')['data-rounds-index-value']).to eq('2')
    end

    it 'exige o campeonato na rota do ADR (404 sem championship_id)' do
      post simulador_projecao_path, params: { guesses: {} }

      expect(response).to have_http_status(:not_found)
    end

    it 'projeta a tabela com os placares do visitante, num Turbo Frame, sem gravar nada' do
      expect do
        preview({ open_match.id => { home: '0', away: '3' }, live_match.id => { home: '4', away: '0' } })
      end.not_to(change { [Core::Match.maximum(:updated_at), Core::Match.pluck(:home_score)] })

      expect(response).to have_http_status(:ok)
      expect(page.at_css('turbo-frame#simulador')).to be_present
      projection = page.css('[data-role="projection"] [data-role="standing-row"]')
      expect(projection.map { |row| team_name(row) })
        .to eq(%w[Fortaleza Cruzeiro Atlético Botafogo])
      expect(projection.first.at_css('[data-role="position-change"]')['aria-label']).to eq('Subiu 2')
    end

    it 'mostra a tabela projetada no lugar da atual, com o botão de zerar a simulação' do
      preview({ open_match.id => { home: '0', away: '3' } })

      frame = page.at_css('turbo-frame#simulador')
      expect(frame.at_css('#table-title').text).to eq('Tabela projetada')
      expect(frame.at_css('[data-role="real-table"]')).to be_nil
      expect(page.css('[data-role="standing-row"]').size).to eq(4)
      reset = frame.at_css('[data-role="reset-simulation"]')
      expect(reset.text.squish).to eq('Zerar simulação')
      expect(reset['href']).to eq(simulador_championship_path(championship))
    end

    it 'aceita a rota do ADR (POST /simulador/projecao com championship_id)' do
      post simulador_projecao_path, params: { championship_id: championship.id,
                                              guesses: { open_match.id => { home: '1', away: '1' } } }

      expect(response).to have_http_status(:ok)
      expect(page.css('[data-role="projection"]')).to be_present
    end

    it 'recusa placares inválidos com 422 e erro por partida' do
      preview({ open_match.id => { home: '-1', away: '2' }, played.id => { home: '9', away: '0' } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.at_css('[data-role="projection"]')).to be_nil
      expect(page.at_css('[data-role="real-table"]')).to be_present
      expect(page.at_css('[data-role="reset-simulation"]')).to be_present
      expect(page.at_css('[data-role="simulation-errors"]').text)
        .to include('placar inválido', 'não é uma partida em aberto')
      input = page.at_css("input[name='guesses[#{open_match.id}][home]']")
      expect(input['aria-invalid']).to eq('true')
      expect(input['value']).to eq('-1')
    end

    it 'limita a 30 projeções por minuto por IP (429)' do
      30.times { preview({}) }
      expect(response).to have_http_status(:ok)

      preview({})

      expect(response).to have_http_status(:too_many_requests)
      expect(page.at_css('turbo-frame#simulador [data-role="rate-limited"]')).to be_present
    end
  end

  it 'aparece no admin do campeonato' do
    sign_in(create(:user, :admin))

    get "/admin/championships/#{championship.id}"

    expect(response.body).to include(simulador_championship_path(championship))
  end
end
