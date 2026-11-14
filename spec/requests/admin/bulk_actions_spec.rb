require 'rails_helper'

RSpec.describe 'Bulk actions of the listings (TICKET-0104)', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }

  def page_html = Nokogiri::HTML5(response.body)
  def own_team(name) = create(:team, manager:, name:)

  def bulk(path, ids, **params)
    post(path, params: { ids: ids.map(&:id), **params }, headers: { 'HTTP_REFERER' => path })
  end

  context 'as gestor' do
    before { sign_in(manager) }

    it 'offers the selection bar with its fields on the lists' do
      create(:match, championship:)

      get '/gestor/teams'
      bar = page_html.at_css('#teams-bulk[data-role="bulk-bar"]')
      expect(bar.css('button').map(&:text)).to eq(['Inscrever no campeonato', 'Remover do campeonato', 'Excluir'])
      expect(bar.css('select[name="championship_id"] option').map(&:text)).to include(championship.to_s)

      get '/gestor/matches'
      expect(page_html.css('#matches-bulk input, #matches-bulk select').map { _1['name'] })
        .to include('shift_amount', 'shift_unit', 'reason')
    end

    it 'deletes the teams without history and lists the kept ones in the flash' do
      free = %w[Alfa Beta Gama].map { own_team(_1) }
      played = [own_team('Delta'), own_team('Épsilon')]
      create(:match, championship:, home_team: played.first, away_team: played.last)

      bulk('/gestor/teams/bulk_destroy', free + played)

      expect(flash[:notice]).to eq('3 excluídos, 2 mantidos porque têm partidas (Delta, Épsilon)')
      expect(Core::Team.where(id: free.map(&:id))).to be_empty
      names = Core::AuditLog.where(action: 'team.destroyed').pluck(:metadata).pluck('name')
      expect(names).to match_array(%w[Alfa Beta Gama])
    end

    it 'keeps teams with players and ignores teams of another gestor' do
      squad = own_team('Com Elenco')
      create(:player, team: squad)
      foreign = create(:team, manager: create(:user, :manager))

      bulk('/gestor/teams/bulk_destroy', [squad, foreign])
      expect(flash[:alert]).to eq('0 excluídos, 1 mantido porque tem jogadores (Com Elenco)')

      bulk('/gestor/teams/bulk_destroy', [foreign])
      expect(flash[:alert]).to eq('Selecione pelo menos um item.')
      expect(foreign.reload).to be_persisted
    end

    it 'enrolls and unenrolls teams, keeping the ones the rules hold' do
      enrolled = own_team('Inscrito')
      fresh = own_team('Novo')
      championship.teams << enrolled

      bulk('/gestor/teams/bulk_enroll', [enrolled, fresh], championship_id: championship.id)
      expect(flash[:notice]).to eq('1 inscrito, 1 não inscrito porque já estava inscrito (Inscrito)')

      create(:match, championship:, home_team: fresh, away_team: enrolled)
      bulk('/gestor/teams/bulk_unenroll', [enrolled, fresh], championship_id: championship.id)
      expect(flash[:alert]).to eq('0 removidos, 2 mantidos porque têm partidas neste campeonato (Inscrito, Novo)')
    end

    it 'refuses to enroll in a championship of another gestor' do
      other = create(:championship, manager: create(:user, :manager))

      bulk('/gestor/teams/bulk_enroll', [own_team('X')], championship_id: other.id)

      expect(flash[:alert]).to eq('Escolha um campeonato seu.')
      expect(other.teams).to be_empty
    end

    it 'moves players, keeping their history and the ones that clash' do
      from = own_team('Origem')
      to = own_team('Destino')
      mover = create(:player, team: from, name: 'Ana', shirt_number: 7)
      clash = create(:player, team: from, name: 'Bia', shirt_number: 10)
      create(:player, team: to, shirt_number: 10)
      settled = create(:player, team: to, name: 'Caio', shirt_number: 11)

      bulk('/gestor/players/bulk_move', [mover, clash, settled], team_id: to.id)

      expect(flash[:notice]).to eq('1 movido, 1 mantido porque tem o número de outro jogador do time (Bia), ' \
                                   '1 mantido porque já está no time (Caio)')
      expect(mover.reload.team).to eq(to)
      expect(Core::AuditLog.find_by(action: 'player.moved').metadata).to include('from' => 'Origem', 'to' => 'Destino')
    end

    it 'deletes players without history only' do
      team = own_team('Elenco')
      free = create(:player, team:, name: 'Livre')
      scored = create(:player, team:, name: 'Pontuado')
      create(:cartola_player_score, player: scored, match: create(:match, championship:, home_team: team))

      bulk('/gestor/players/bulk_destroy', [free, scored])

      expect(flash[:notice]).to eq('1 excluído, 1 mantido porque tem histórico no Esquadrão (Pontuado)')
    end

    it 'reschedules scheduled matches with a reason and keeps the ones that started' do
      kickoff = 3.days.from_now.change(usec: 0)
      scheduled = create(:match, championship:, match_date: kickoff)
      live = create(:match, championship:, status: 'live', match_date: 1.hour.ago)

      bulk('/gestor/matches/bulk_reschedule', [scheduled, live], shift_amount: 2, shift_unit: 'days',
                                                                 reason: 'chuva')

      expect(flash[:notice]).to eq("1 reagendada, 1 mantida porque não está agendada (#{live})")
      expect(scheduled.reload.match_date).to eq(kickoff + 2.days)
      expect(Core::AuditLog.find_by(action: 'match.rescheduled').metadata).to include('reason' => 'chuva')
    end

    it 'asks for the shift and the reason before rescheduling' do
      match = create(:match, championship:)

      bulk('/gestor/matches/bulk_reschedule', [match], shift_amount: 0, shift_unit: 'days', reason: 'x')
      expect(flash[:alert]).to start_with('Informe de quantos dias ou horas')

      bulk('/gestor/matches/bulk_reschedule', [match], shift_amount: 3, shift_unit: 'hours', reason: ' ')
      expect(flash[:alert]).to eq('Informe o motivo do reagendamento.')
    end

    it 'deletes scheduled matches without predictions or lances' do
      free = create(:match, championship:)
      predicted = create(:match, championship:)
      create(:bolao_prediction, match: predicted, pool: create(:bolao_pool, championship:, owner: manager))
      finished = create(:match, championship:, status: 'finished', match_date: 1.day.ago)

      bulk('/gestor/matches/bulk_destroy', [free, predicted, finished])

      expect(flash[:notice]).to eq("1 excluído, 1 mantido porque tem palpites (#{predicted}), " \
                                   "1 mantido porque não está agendada (#{finished})")
      expect(Core::Match.exists?(free.id)).to be(false)
    end
  end

  context 'as admin' do
    before { sign_in(create(:user, :admin)) }

    it 'approves pending managers and keeps the others' do
      pending = create_list(:user, 2, :pending_manager)
      regular = create(:user, email_address: 'comum@example.com')

      bulk('/admin/users/bulk_approve_manager', [*pending, regular])

      expect(flash[:notice]).to eq('2 aprovados, 1 mantido porque não tem pedido pendente (comum@example.com)')
      expect(pending.map { _1.reload.manager_status }).to all(eq('approved'))
      expect(Core::AuditLog.where(action: 'user.manager_approved').count).to eq(2)
    end
  end

  it 'refuses bulk approval to gestores' do
    sign_in(manager)

    bulk('/admin/users/bulk_approve_manager', [create(:user, :pending_manager)])

    expect(response).to have_http_status(:forbidden)
  end
end
