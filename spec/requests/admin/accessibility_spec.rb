require 'rails_helper'

RSpec.describe 'Admin accessibility (TICKET-0081)', type: :request do
  before { sign_in(create(:user, :admin)) }

  def page_html = Nokogiri::HTML(response.body)

  describe 'scouts tabs' do
    let(:match) { create(:match, status: 'live', match_date: 1.hour.ago) }
    let!(:striker) { create(:player, team: match.home_team, position: 'ATA', name: 'Atacante Casa') }

    before { create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME) }

    it 'wires each tab to its panel with roving tabindex and keyboard navigation' do
      get '/admin/matchscouts', params: { match_id: match.id }

      tabs = page_html.css('[role="tab"]')
      expect(tabs.map { |tab| [tab['aria-controls'], tab['aria-selected'], tab['tabindex']] })
        .to eq([%w[scouts-panel-home true 0], %w[scouts-panel-away false -1]])
      expect(page_html.at_css('[role="tablist"]')['data-action']).to eq('keydown->scouts#navigate')
      panel = page_html.at_css('#scouts-panel-home')
      expect([panel['role'], panel['aria-labelledby']]).to eq(%w[tabpanel scouts-tab-home])
      expect(tabs.first['class']).to include('aria-[selected=true]:bg-cartola', 'aria-[selected=false]:bg-white')
    end

    it 'labels the 40px steppers with the stat and the player' do
      get '/admin/matchscouts', params: { match_id: match.id }

      steppers = page_html.css("[data-player-id='#{striker.id}'] button[data-action='scouts#step']")
      expect(steppers.map { _1['aria-label'] })
        .to include('Diminuir Gol de Atacante Casa', 'Aumentar Gol de Atacante Casa')
      expect(steppers.first['class']).to include('h-10', 'w-10', 'disabled:cursor-not-allowed')
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
      create(:championship)

      get '/admin/championships'

      expect(page_html.css('[data-role="admin-table-action"]').map { _1['class'] }).to all(include('h-10', 'w-10'))
    end
  end
end
