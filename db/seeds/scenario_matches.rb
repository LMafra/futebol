# The six matches of the Copa dos Testes (scenarios.rb), one per situation of the match page:
#   rodada 1: pontuada e depois editada (placar e pontos refeitos), e pontuada e revertida com motivo;
#   rodada 2: encerrada sem pontuação (como a fila antiga deixava), e ao vivo com um lance desfeito;
#   rodada 3: agendada com o horário já passado, e agendada remarcada com motivo.
module Seeds
  def self.scenario_matches(matches, manager)
    edited, reverted, finished, live, _overdue, upcoming = matches
    scenario_edited(edited, manager)
    scenario_reverted(reverted, manager)
    scenario_finished(finished, manager)
    scenario_live(live, manager)
    Bulk::RescheduleMatches.call([upcoming], shift: 7.days, reason: 'Campo interditado pela prefeitura',
                                             actor: manager, ip_address: scenarios_ip)
  end

  # Scored 2 × 1; then the gestor records a missed goal (2 × 2) and picks the highlight, each one a rescore.
  def self.scenario_edited(match, actor)
    scenario_lances(match, actor, [[:home, 9, 'goals', 12, 'first_half'], [:home, 10, 'assists', 12, 'first_half'],
                                   [:away, 7, 'goals', 30, 'first_half'], [:home, 11, 'goals', 5, 'second_half'],
                                   [:away, 4, 'yellow_cards', 20, 'second_half'],
                                   [:home, 1, 'saves', 33, 'second_half']])
    scenario_finalize(match, actor)
    scenario_lances(match, actor, [[:away, 9, 'goals', 44, 'second_half']])
    Scouts::MarkParticipation.call(match:, player: scenario_player(match, :home, 9), flags: { highlight: true },
                                   actor:, ip_address: scenarios_ip)
  end

  def self.scenario_reverted(match, actor)
    scenario_lances(match, actor, [[:home, 7, 'goals', 18, 'first_half'], [:away, 11, 'goals', 40, 'second_half']])
    scenario_finalize(match, actor)
    RevertMatchPointsService.call(match:, actor:, ip_address: scenarios_ip, reason: 'Súmula com gol em impedimento')
  end

  # Finished without points, as the old scoring queue left them: "Finalizar partida" scores it.
  def self.scenario_finished(match, actor)
    scenario_lances(match, actor, [[:away, 9, 'goals', 25, 'first_half']])
    match.reload.finish_match!
  end

  def self.scenario_live(match, actor)
    scenario_lances(match, actor, [[:home, 9, 'goals', 8, 'first_half'], [:home, 8, 'assists', 8, 'first_half'],
                                   [:away, 10, 'red_cards', 31, 'first_half'], [:away, 11, 'goals', 3, 'second_half']])
    Scouts::UndoLast.call(match:, player: scenario_player(match, :away, 11), stat: 'goals', actor:,
                          ip_address: scenarios_ip)
  end

  def self.scenario_finalize(match, actor)
    home_score, away_score = Cartola::PlayerScore.score_for(match)
    FinalizeMatchService.call(match:, home_score:, away_score:, actor:, ip_address: scenarios_ip)
  end

  # Each lance: [side, shirt number, stat, minute, period].
  def self.scenario_lances(match, actor, lances)
    lances.each do |side, shirt, stat, minute, period|
      event = Cartola::ScoutEvent.new(match:, player: scenario_player(match, side, shirt), stat:, minute:, period:)
      result = Scouts::RecordEvent.call(event:, actor:, ip_address: scenarios_ip)
      raise "lance #{match.external_id}: #{result.errors.to_sentence}" unless result.success?
    end
  end

  def self.scenario_player(match, side, shirt)
    match.public_send(:"#{side}_team").players.find_by!(shirt_number: shirt)
  end
end
