module SimuladorHelper
  # standings: Simulador::StandingsCalculator::Standing, or [standing, change] pairs for a projection.
  def simulador_rows(standings, teams)
    short_names = teams.to_h { |team| [team.id, team.short_name] }
    standings.map do |standing, change|
      Ui::StandingsTableComponent::Row.new(
        position: standing.position, team_name: standing.team_name, short_name: short_names[standing.team_id],
        played: standing.played, wins: standing.wins, draws: standing.draws, losses: standing.losses,
        goal_difference: standing.goal_difference, points: standing.points, change:
      )
    end
  end

  # Round shown first by the carousel: the first one with an error, else the one the visitor was on.
  # rounds: [[round, matches], ...] in display order.
  def simulador_round_index(rounds, simulation, requested)
    with_error = rounds.index { |_round, matches| matches.any? { |match| simulation.errors[match.id.to_s] } }
    with_error || requested.to_i.clamp(0, rounds.size - 1)
  end

  # What the visitor typed (kept even when invalid), else the parsed guess (live matches come prefilled).
  def simulador_goals(simulation, raw, match, side)
    raw.dig(match.id.to_s, side.to_s).presence || simulation.guesses.dig(match.id, side)
  end
end
