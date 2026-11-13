require 'rails_helper'

RSpec.describe 'Admin/Gestor consistency (TICKET-0084)', type: :request do
  def page_html = Nokogiri::HTML(response.body)

  def option_texts(name) = page_html.css("select[name='#{name}'] option[value]:not([value=''])").map(&:text)

  context 'as admin' do
    let(:admin) { create(:user, :admin) }

    before { sign_in(admin) }

    it 'translates status filters and attribute headers' do
      create(:match)

      get '/admin/matches'
      expect(option_texts('q[status_eq]')).to eq(['Agendada', 'Ao vivo', 'Encerrada', 'Pontuada', 'Revertida'])
      expect(page_html.css('th').map { _1.text.squish }).to include('Data da partida', 'Pontuada em')

      get '/admin/csv_imports'
      expect(option_texts('q[status_eq]')).to eq(['Na fila', 'Processando', 'Concluída', 'Falhou'])

      get '/admin/users'
      expect(option_texts('q[role_eq]')).to eq(%w[Usuário Gestor Administrador])
      expect(option_texts('q[manager_status_eq]')).to eq(%w[Nenhum Pendente Aprovado Recusado])
    end

    it 'labels prize places in the championship form' do
      get "/admin/championships/#{create(:championship).id}/edit"

      expect(page_html.css('label').map { _1.text.squish }).to include('1º lugar', '2º lugar', '3º lugar')
      expect(response.body).not_to include('First place')
    end

    it 'links the Pontuação pendente KPI to the scope and counts only active championships' do
      active = create(:championship)
      create(:match, championship: active, status: 'scheduled', match_date: 1.day.from_now)
      done = create(:championship)
      create(:match, championship: done, status: 'scored', match_date: 2.days.ago, home_score: 1, away_score: 0,
                     scores_calculated_at: 1.day.ago)

      get '/admin'

      kpis = page_html.css('[data-role="admin-kpi"]').to_h { [_1['data-label'], _1] }
      expect(kpis['Pontuação pendente']['href']).to eq('/admin/matches?scope=encerradas_sem_pontuacao')
      expect(kpis['Campeonatos ativos'].at_css('.font-numeric').text.strip).to eq('1')
      get '/admin/matches', params: { scope: 'encerradas_sem_pontuacao' }
      expect(response).to have_http_status(:ok)
    end

    it 'sends the preview CTA to the finalizer without the simulated score' do
      match = create(:match, status: 'live', match_date: 1.hour.ago)

      get '/admin/bolaopreview', params: { match_id: match.id, candidate_home: 2, candidate_away: 1 }

      cta = page_html.at_css('[data-role="confirm-score"]')
      expect([cta.text.strip, cta['href']])
        .to eq(['Ir para a finalização', "/admin/matchfinalizer?match_id=#{match.id}"])
      expect(response.body).to include('vale o placar dos scouts')
      expect(page_html.at_css('[data-role="preview"] [data-role="empty-state"]')).to be_present
    end

    it 'speaks the match status in Portuguese when it cannot be finalized' do
      match = create(:match, status: 'finished', match_date: 1.day.ago, home_score: 1, away_score: 0)

      get '/admin/bolaopreview', params: { match_id: match.id, candidate_home: 2, candidate_away: 1 }

      expect(response.body).to include('A partida está encerrada')
      expect(response.body).not_to include('está finished')
    end

    describe 'match page button roles' do
      let(:match) { create(:match, status: 'live', match_date: 1.hour.ago) }

      def header_link(text) = page_html.css('[data-test-page-header] a').find { _1.text.strip == text }

      it 'makes Scouts the only primary before scouts exist' do
        get "/admin/matches/#{match.id}"

        expect(header_link('Scouts')['class']).to include('bg-cartola')
        %w[Finalizar Histórico].each { expect(header_link(_1)['class']).to include('bg-white') }
        expect(header_link('Preview do Bolão')['class']).to include('bg-white')
      end

      it 'moves the primary to Finalizar once scouts exist' do
        create(:cartola_player_score, match:, player: create(:player, team: match.home_team))

        get "/admin/matches/#{match.id}"

        expect(header_link('Finalizar')['class']).to include('bg-cartola')
        expect(header_link('Scouts')['class']).to include('bg-white')
      end

      it 'shows Reverter pontuação as danger' do
        scored = create(:match, status: 'scored', match_date: 1.day.ago, home_score: 1, away_score: 0,
                                scores_calculated_at: 1.hour.ago)

        get "/admin/matches/#{scored.id}"

        expect(header_link('Reverter pontuação')['class']).to include('bg-loss-solid', 'text-paper')
      end
    end

    it 'renders the CSV import status component on the show page' do
      csv_import = create(:csv_import, status: 'completed', rows_processed: 3)

      get "/admin/csv_imports/#{csv_import.id}"

      expect(page_html.at_css('[data-role="status"]').text).to eq('Concluída')
      expect(page_html.at_css('[data-role="rows"]').text).to eq('3 linhas processadas')
      get '/admin/csv_imports/new'
      expect(page_html.at_css('.inline-hints').text).to include('Colunas esperadas')
      expect(page_html.at_css('legend').text.strip).to eq('Arquivo CSV')
    end

    it 'flags the finalizer confirmation inline with ARIA' do
      match = create(:match, status: 'live', match_date: 2.hours.ago)
      create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME)
      Cartola::RecordScoutsService.call(
        match:, actor: admin, ip_address: '127.0.0.1',
        rows: [{ player_id: create(:player, team: match.home_team, position: 'ATA').id, team_id: match.home_team_id,
                 played: true, goals: 1 }]
      )

      post '/admin/matchfinalizer/finalize', params: { finalization: { match_id: match.id, score_confirmation: '0x0' } }

      field = page_html.at_css('input[name="finalization[score_confirmation]"]')
      expect([field['aria-invalid'], field['aria-describedby']]).to eq(%w[true score-confirmation-error])
      expect(page_html.at_css('#score-confirmation-error').text).to include('não confere')
      expect(page_html.at_css('label[for="finalization_score_confirmation"]').text.squish)
        .to eq('Confirme o placar, ex.: 2x1 (obrigatório)')
    end

    it 'uses the same required marker in resource forms' do
      get '/admin/championships/new'

      expect(page_html.at_css('label[for="championship_name"]').text.squish).to eq('Nome (obrigatório)')
      expect(response.body).not_to include('<abbr title="required">')
    end
  end

  context 'as gestor' do
    let(:manager) { create(:user, :manager) }
    let(:championship) { create(:championship, manager:) }
    let(:team) { create(:team) }

    before do
      create(:match, championship:, home_team: team, match_date: 1.day.from_now)
      create(:player, team:)
      sign_in(manager)
    end

    it 'uses icon row actions on gestor tables' do
      %w[players teams].each do |resource|
        get "/gestor/#{resource}"

        actions = page_html.css('[data-role="admin-table-action"]')
        expect(actions).to be_present
        expect(actions.first['aria-label']).to start_with('Abrir ')
        expect(actions.first['title']).to eq(actions.first['aria-label'])
      end
    end

    it 'schedules matches with a datetime-local field' do
      get '/gestor/matches/new'

      expect(page_html.at_css('input[name="match[match_date]"]')['type']).to eq('datetime-local')
    end

    it 'names the championship card links by their task' do
      get '/gestor'

      links = page_html.css("[data-championship-id='#{championship.id}'] p a").map { _1.text.strip }
      expect(links).to eq(['Agendar partida', 'Editar campeonato'])
    end
  end
end
