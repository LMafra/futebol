require 'rails_helper'

RSpec.describe 'Admin accessibility (TICKET-0081)', type: :request do
  before { sign_in(create(:user, :admin)) }

  def page_html = Nokogiri::HTML5(response.body)

  describe 'scouts tabs' do
    let(:match) { create(:match, status: 'live', match_date: 1.hour.ago) }
    let!(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Atacante Casa') }

    before { create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME) }

    it 'wires each tab to its panel with roving tabindex and keyboard navigation' do
      get "/admin/matches/#{match.id}"

      tabs = page_html.css('[role="tab"]')
      expect(tabs.map { |tab| [tab['aria-controls'], tab['aria-selected'], tab['tabindex']] })
        .to eq([%w[side-panel-home true 0], %w[side-panel-away false -1]])
      expect(page_html.at_css('[role="tablist"]')['data-action']).to eq('keydown->tabs#navigate')
      panel = page_html.at_css('#side-panel-home')
      expect([panel['role'], panel['aria-labelledby']]).to eq(%w[tabpanel side-tab-home])
      expect(tabs.first['class']).to include('aria-[selected=true]:bg-cartola', 'aria-[selected=false]:bg-white')
    end

    it 'labels the lance buttons and the undo with the stat and the player' do
      Scouts::RecordEvent.call(event: Cartola::ScoutEvent.new(match:, player: striker, stat: 'goals'),
                               actor: create(:user, :admin), ip_address: '127.0.0.1')

      get "/admin/matches/#{match.id}"

      line = page_html.at_css("[data-player-id='#{striker.id}']")
      expect(line.css('a[data-modal-open="modal-lance"]').map { _1['aria-label'] })
        .to include('Lançar gol de Atacante Casa')
      undo = line.at_css('form[action$="/undo_event"] button')
      expect(undo['aria-label']).to eq('Desfazer o último lance de gol de Atacante Casa')
      expect(undo['class']).to include('h-10', 'w-10')
    end
  end

  describe 'sidebar' do
    it 'marks the current page and exposes the section toggle state' do
      get '/admin/championships'

      sidebar = page_html.at_css('[data-role="craquefy-admin-sidebar"]')
      current = sidebar.css('[aria-current="page"]')
      expect(current.map { _1.text.squish }).to eq(['Campeonatos'])
      toggles = sidebar.css('button[data-menu-button]')
      expect(toggles).to be_present
      expect(toggles.map { _1['aria-expanded'] }).to all(match(/\A(true|false)\z/))
      expect(toggles.map { _1['aria-label'] }.compact).to all(start_with('Expandir ou recolher'))
      expect(sidebar.css('[aria-label="Ativar seção"]')).to be_empty
    end
  end

  describe 'empty results' do
    it 'renders the empty state with a clear-filters link when filters match nothing' do
      create(:championship, name: 'Copa Real')

      get '/admin/championships', params: { q: { name_cont: 'Inexistente' } }

      expect(page_html.at_css('[data-role="empty-state"]')).to be_present
      expect(page_html.at_css('a[data-role="clear-filters"]')['href']).to eq('/admin/championships')
    end
  end

  describe 'pagination' do
    it 'flags the current page with aria-current and 40px targets' do
      create_list(:match, 35)

      get '/admin/matches'

      current = page_html.at_css('[data-test-pagination] a[aria-current="page"]')
      expect(current.text.squish).to eq('1')
      expect(current['class']).to include('min-h-10', 'min-w-10')
    end
  end

  describe 'flash' do
    it 'renders no flash container without messages' do
      get '/admin/championships'

      expect(response.body).not_to include('data-role="craquefy-admin-flashes"')
    end
  end

  describe 'row actions' do
    it 'renders 40px icon actions' do
      create(:player)

      get '/admin/players'

      expect(page_html.css('[data-role="admin-table-action"]').map { _1['class'] }).to all(include('h-10', 'w-10'))
    end
  end
end
