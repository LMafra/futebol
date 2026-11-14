require 'rails_helper'

RSpec.describe 'Participantes › Esquadrão', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }
  let(:match) do
    create(:match, championship:, round: 2, status: 'scored', match_date: 3.days.ago, home_score: 1, away_score: 0,
                   scores_calculated_at: 2.days.ago)
  end
  let!(:star) { scored_player('Craque', 'ATA', 12, match.home_team) }
  let!(:playmaker) { scored_player('Meia', 'MEI', 6, match.home_team) }
  let!(:sub) { scored_player('Reserva', 'ATA', 3, match.away_team) }
  let!(:keeper) { scored_player('Frangueiro', 'GOL', -1, match.away_team) }
  let(:ana) { create(:user, name: 'Ana') }
  let(:bia) { create(:user, name: 'Bia') }
  let!(:ana_lineup) { lineup_for(ana, star) }
  let!(:bia_lineup) { lineup_for(bia, sub) }

  def page = Nokogiri::HTML5(response.body)

  def scored_player(name, position, points, team)
    create(:player, name:, position:, team:).tap { create(:cartola_player_score, player: _1, match:, points:) }
  end

  def lineup_for(user, captain)
    create(:cartola_lineup, championship:, round: 2, squad: create(:cartola_squad, user:),
                            include_players: [captain], captain:)
  end

  def update_lineup(lineup, reason:, swap: [sub, star], area: 'admin')
    out, into = swap
    post "/#{area}/esquadrao/update_lineup",
         params: { lineup_id: lineup.id,
                   lineup: { formation: lineup.formation, captain_id: into.id, reason:,
                             player_ids: lineup.selected_players.map(&:id) - [out.id] + [into.id] } }
  end

  context 'as admin' do
    before { sign_in(create(:user, :admin)) }

    it 'mostra ranking, gabarito da rodada (seleção ideal com capitão) e a escalação escolhida' do
      get '/admin/esquadrao', params: { championship_id: championship.id, rodada: 2, escalacao: bia_lineup.id }

      expect(response).to have_http_status(:ok)
      expect(page.css('[data-role="ranking-row"]').map { _1.css('td').first(3).map { |cell| cell.text.squish } })
        .to eq([%w[1 Ana 24.00], %w[2 Bia 6.00]])
      ideal = page.at_css('[data-role="ideal-lineup"]')
      expect(ideal.text.squish).to include('33.00 pts')
      expect(ideal.css('[data-role="ideal-player"]').map { _1.text.squish })
        .to eq(["Meia MEI · #{playmaker.team.short_name} 6.00", "Craque ATA · #{star.team.short_name} C 12.00",
                "Reserva ATA · #{sub.team.short_name} 3.00"])
      expect(page.css('[data-role="player-points"] tbody tr').size).to eq(4)
      detail = page.at_css('[data-role="lineup-detail"]')
      expect(detail['data-lineup-id']).to eq(bia_lineup.id.to_s)
      expect(detail.at_css('[data-role="lineup-points"]').text.squish).to eq('6.00 pts')
      reserve = detail.css('[data-role="pitch-player"]').find { _1.text.include?('Reserva') }
      expect(reserve.at_css('[data-role="captain"]')).to be_present
      expect(reserve.at_css('[data-role="pitch-points"]').text).to eq('6.00 pts')
      expect(detail.at_css('a[href*="editar=1"]').text).to eq('Editar escalação')
    end

    it 'corrige a escalação com motivo: troca jogador e capitão, audita e o ranking acompanha' do
      expect { update_lineup(bia_lineup, reason: 'Escalou o reserva sem querer') }
        .to change { Core::AuditLog.where(action: 'esquadrao.lineup_corrected').count }.by(1)

      expect(response).to redirect_to(
        "/admin/esquadrao?#{{ championship_id: championship.id, escalacao: bia_lineup.id, rodada: 2 }.to_query}#lineups"
      )
      expect(bia_lineup.reload.captain).to eq(star)
      expect(bia_lineup.players).not_to include(sub)
      log = Core::AuditLog.find_by(action: 'esquadrao.lineup_corrected')
      expect(log.metadata).to include('reason' => 'Escalou o reserva sem querer', 'user_id' => bia.id, 'round' => 2)
      expect(log.metadata.dig('before', 'captain_id')).to eq(sub.id)
      expect(log.metadata.dig('after', 'captain_id')).to eq(star.id)

      follow_redirect!
      expect(page.css('[data-role="ranking-row"]').map { _1.css('td').first(3).map { |cell| cell.text.squish } })
        .to eq([%w[1 Ana 24.00], %w[1 Bia 24.00]])
    end

    it 'sem motivo volta ao formulário preenchido, com o alerta, sem mudar a escalação' do
      update_lineup(bia_lineup, reason: '')

      expect(response.location).to include('editar=1', "escalacao=#{bia_lineup.id}")
      expect(bia_lineup.reload.captain).to eq(sub)
      expect(response.location).not_to include('#')
      follow_redirect!
      expect(page.text).not_to include('lineup_id')
      form = page.at_css('[data-role="lineup-form"]')
      expect(form.at_css('[role="alert"]').text).to include('Motivo é obrigatório')
      expect(form.at_css("#lineup_player_#{star.id}")['checked']).to be_present
      expect(form.at_css("#lineup_player_#{sub.id}")['checked']).to be_nil
      expect(form.at_css('#lineup_reason')['aria-invalid']).to eq('true')
    end
  end

  context 'as gestor' do
    before { sign_in(manager) }

    it 'vê e corrige as escalações dos seus campeonatos' do
      get '/gestor/esquadrao', params: { rodada: 2 }

      expect(page.css('[data-role="ranking-row"]').size).to eq(2)

      update_lineup(bia_lineup, reason: 'Combinado no grupo', area: 'gestor')
      expect(bia_lineup.reload.captain).to eq(star)
    end

    it 'não alcança campeonatos de outro gestor' do
      foreign = create(:championship, manager: create(:user, :manager), name: 'Copa Alheia')
      lineup = create(:cartola_lineup, championship: foreign, round: 1)

      get '/gestor/esquadrao', params: { championship_id: foreign.id }
      expect(page.css('#championship_id option').map(&:text)).not_to include(foreign.to_s)

      post '/gestor/esquadrao/update_lineup',
           params: { lineup_id: lineup.id, lineup: { formation: '4-4-2', reason: 'x', player_ids: [] } }
      expect(lineup.reload.formation).to eq('4-3-3')
    end

    it 'leva as URLs antigas de Escalações do Esquadrão para a página nova' do
      get "/gestor/esquadrao_lineups/#{bia_lineup.id}"

      expect(response).to redirect_to('/gestor/esquadrao')
    end
  end
end
