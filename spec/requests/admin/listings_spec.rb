require 'rails_helper'

RSpec.describe 'Admin and Gestor listings on Ui::CollectionComponent (TICKET-0103)', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, status: 'draft') }
  let(:team) { create(:team, manager:, name: 'Azul FC') }

  def page_html = Nokogiri::HTML5(response.body)
  def collection(id) = page_html.at_css("section##{id}[data-controller='collection']")
  def week_link(label) = page_html.at_css("[data-role='agenda-weeks'] a[aria-label='#{label}']")

  before do
    championship.teams << team
    create(:player, team:, name: 'Beto', shirt_number: 9)
    create(:player, team:, name: 'Ana', shirt_number: 10)
    create(:match, championship:, round: 2, home_team: team)
    create(:bolao_pool, championship:, owner: manager)
  end

  context 'as admin' do
    before do
      create(:audit_log, action: 'revert', metadata: { reason: 'súmula' })
      create(:csv_import)
      sign_in(create(:user, :admin))
    end

    it 'renders every listing in its mode, without the ActiveAdmin table' do
      { championships: :cards, teams: :grid, players: :table, matches: :grouped, users: :table, pools: :cards,
        csv_imports: :table, audit_logs: :timeline }.each do |resource, mode|
        get "/admin/#{resource}"

        expect(response).to have_http_status(:ok)
        expect(collection(resource.to_s.dasherize)&.[]('data-mode')).to eq(mode.to_s), resource.to_s
        expect(page_html.css('table.data-table')).to be_empty
      end
    end

    it 'switches teams to a table and matches to the agenda' do
      get '/admin/teams', params: { view: 'table' }
      expect(collection('teams')['data-mode']).to eq('table')

      get '/admin/matches', params: { view: 'agenda' }
      expect(collection('matches')['data-mode']).to eq('agenda')
    end

    it 'sorts through ?sort=&dir= and ignores unknown columns' do
      get '/admin/players', params: { sort: 'name', dir: 'desc' }
      names = page_html.css('#players [data-role="collection-primary"]').map { _1.text.strip }
      expect(names).to eq(%w[Beto Ana])
      expect(page_html.at_css('#players th[aria-sort="descending"]').text).to include('Jogador')

      get '/admin/players', params: { sort: 'drop table', dir: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'shows the counts and the audit trail' do
      get '/admin/teams'
      card = page_html.at_css("#teams-item-#{team.id}").text.squish
      expect(card).to eq("#{team.short_name} Azul FC Jogadores 2 jogadores")

      get '/admin/audit_logs'
      expect(page_html.at_css('#audit-logs [data-role="collection-item"]').text).to include('revert', 'súmula')
    end
  end

  context 'as gestor' do
    before { sign_in(manager) }

    it 'renders the gestor listings and offers to continue the draft' do
      %w[championships teams players matches pools].each do |resource|
        get "/gestor/#{resource}"

        expect(response).to have_http_status(:ok)
        expect(collection(resource)).to be_present, resource
      end

      get '/gestor/championships'
      card = page_html.at_css("#championships-item-#{championship.id}").text.squish
      expect(card).to include('Times 2', 'Partidas 1', 'rascunho', 'Continuar rascunho')
    end

    it 'shows the next step of each match' do
      live = create(:match, championship:, status: 'live', match_date: 1.hour.ago, home_team: team)

      get '/gestor/matches'

      steps = page_html.css('#matches [data-role="match-step"]').to_h { [_1.text, _1['href']] }
      expect(steps).to include('Registrar lances' => "/gestor/matches/#{live.id}")
      expect(steps.keys).to include('Editar partida')
    end

    it 'walks the agenda week by week, also through an empty week' do
      monday = Date.new(2026, 11, 9)
      create(:match, championship:, match_date: Time.zone.local(2026, 11, 15, 16), home_team: team)

      get '/gestor/matches', params: { view: 'agenda', q: { match_date_gteq: '2026-11-11' } }
      expect(page_html.at_css('[data-role="agenda-week"]').text).to eq('Semana de 09/11 a 15/11')
      expect(page_html.css('#matches [data-role="collection-group"] h3').map(&:text)).to eq(['Domingo, 15/11/2026'])

      get week_link('Próxima semana')['href']
      next_week = "Semana de #{(monday + 7).strftime('%d/%m')} a #{(monday + 13).strftime('%d/%m')}"
      expect(page_html.at_css('[data-role="agenda-week"]').text).to eq(next_week)
      expect(page_html.at_css('[data-role="empty-state"]')).to be_present
      expect(page_html.at_css('.active-filters-title').text.squish).to eq('Filtros ativos')
      expect(week_link('Semana anterior')).to be_present
    end

    it 'opens the round of the next match by default' do
      get '/gestor/matches'

      group = page_html.at_css('#matches details[data-role="collection-group"][open]')
      expect(group.at_css('summary').text).to include('Rodada 2')
    end
  end
end
