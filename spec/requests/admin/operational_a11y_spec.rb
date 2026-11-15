require 'rails_helper'

RSpec.describe 'Console operacional a11y (TICKET-0121)', type: :request do
  include ViewComponent::TestHelpers

  before { sign_in(create(:user, :admin)) }

  it 'keeps StatusBadge triple encoding (icon + text + color)' do
    page = render_inline(Ui::StatusBadgeComponent.new(status: :live))

    badge = page.at_css('[data-role="status-badge"]')
    expect(badge.at_css('[data-role="status-badge-icon"]')).to be_present
    expect(badge.at_css('[data-role="status-badge-text"]').text.squish).to eq('Ao vivo')
    expect(badge['class']).to include('bg-cartola', 'text-ink')
  end

  it 'uses dotted abbr titles on standings headers' do
    source = File.read(Rails.root.join('app/components/ui/standings_table_component.html.erb'))
    expect(source).to include('decoration-dotted', 'title="Pontos"', 'title="Saldo de gols"')
  end

  it 'uses imperative finalize labels and avoids OK' do
    match = create(:match, status: 'live', match_date: 1.hour.ago)
    create(:cartola_player_score, match:, player: create(:player, team: match.home_team), goals: 1)

    get "/admin/matches/#{match.id}?modal=finalize"

    expect(response.body).to include('Finalizar e Pontuar Partida', 'Revisar Lances')
    expect(response.body).not_to include('>OK<')
  end

  it 'keeps table/KPI numbers on ink/graphite (contrast ≥7:1 gate)' do
    expect(File.read(Rails.root.join('app/components/ui/kpi_card_component.html.erb'))).to include('text-ink')
    expect(File.read(Rails.root.join('app/components/ui/admin_table_component.html.erb'))).to include('text-ink')
    expect(File.read(Rails.root.join('app/assets/stylesheets/active_admin.css'))).not_to match(/text-gray-400/)
  end
end
