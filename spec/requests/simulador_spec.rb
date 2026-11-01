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
    it 'é público: mostra a tabela atual e o formulário dos jogos em aberto (200)' do
      get simulador_championship_path(championship)

      expect(response).to have_http_status(:ok)
      expect(table_names('#real-table-title + section')).to eq(%w[Atlético Cruzeiro Fortaleza Botafogo])
      expect(page.css('[data-role="open-match"]').map { |li| li['data-match-id'].to_i })
        .to eq([live_match.id, open_match.id])
      expect(page.at_css("input[name='guesses[#{live_match.id}][home]']")['value']).to eq('1')
      expect(page.at_css("input[name='guesses[#{played.id}][home]']")).to be_nil
    end

    it 'usa o campeonato mais recente em /simulador' do
      get simulador_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(championship.to_s)
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
  end

  describe 'POST /simulador/:championship_id/preview' do
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
