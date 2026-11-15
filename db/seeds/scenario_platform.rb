# The platform cases of the cenários de teste (scenarios.rb): a pending and a rejected manager request, an
# anonymized participant, a draft championship, a corrected Esquadrão lineup and two CSV imports (one fails).
module Seeds
  def self.scenario_platform(manager)
    admin = Core::User.where(role: :admin).order(:id).first!
    scenario_lineup_correction(manager)
    scenario_users(admin)
    scenario_draft(manager)
    scenario_csv_imports
  end

  # In the gestor's Copa da Várzea Paulista: demo1's captain changed by the organizer.
  def self.scenario_lineup_correction(manager)
    championship = manager.managed_championships.find_by!(external_id: 'varzea-paulista-2026')
    lineup = Cartola::Lineup.joins(squad: :user).find_by!(championship:,
                                                          core_users: { email_address: 'demo1@demo.local' })
    players = lineup.selected_players
    picks = { formation: lineup.formation, player_ids: players.map(&:id),
              captain_id: players.find { |player| player.id != lineup.captain_id }.id }
    Cartola::LineupCorrection.call(lineup:, picks:, reason: 'Capitão trocado a pedido do participante',
                                   actor: manager, ip_address: scenarios_ip) || raise('lineup correction failed')
  end

  # Olga (anonimo@demo.local) is in the Bolão dos Testes, so the ranking keeps her points without her name.
  def self.scenario_users(admin)
    Users::RequestManagerService.call(user: scenario_user('pedido@demo.local', 'Paula Pedido'),
                                      ip_address: scenarios_ip)
    rejected = scenario_user('recusado@demo.local', 'Rui Recusado')
    Users::RequestManagerService.call(user: rejected, ip_address: scenarios_ip)
    Users::ReviewManagerRequestService.call(user: rejected, decision: :rejected, actor: admin,
                                            ip_address: scenarios_ip, reason: 'Nenhum campeonato indicado no pedido')
    Users::AnonymizeService.call(user: Core::User.find_by!(email_address: 'anonimo@demo.local'), actor: admin,
                                 ip_address: scenarios_ip)
  end

  def self.scenario_draft(manager)
    Core::Championship.create!(external_id: 'rascunho-copa-feminina-2026', name: 'Copa Feminina de Futsal',
                               season: 2026, manager:, status: 'draft', kind: 'futsal', gender: 'feminino')
  end

  # One import adds the return leg of round 4; the other fails on a team nobody registered.
  def self.scenario_csv_imports
    kickoff = (Time.current + 10.days).change(hour: 10)
    scenario_csv_import('copa-dos-testes-rodada-4.csv',
                        ["testes-r4-atc-vnt,copa-testes-2026,team-atc,team-vnt,#{kickoff.iso8601},4",
                         "testes-r4-udp-ece,copa-testes-2026,team-udp,team-ece,#{(kickoff + 2.hours).iso8601},4"])
    scenario_csv_import('time-desconhecido.csv',
                        ["testes-r5-xyz-vnt,copa-testes-2026,team-xyz,team-vnt,#{kickoff.iso8601},5"])
  end

  def self.scenario_csv_import(filename, rows)
    csv = ['external_id,championship,home_team,away_team,match_date,round', *rows].join("\n")
    import = Core::CsvImport.create!(csv_file: scenario_blob(csv, filename, 'text/csv'))
    ProcessCsvImportJob.perform_now(import.id)
  end
end
