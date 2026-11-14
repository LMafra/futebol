# Panels of the championship and team pages, shared by /admin and /gestor (ADR 0006 navigation tree): a
# championship shows its enrolled teams, matches by round and bolões; a team shows its players.
module AdminRecordPanels
  def self.championship(context, championship, namespace)
    AdminChampionshipEnrollment.panel(context, championship, namespace)
    matches = championship.matches.includes(:home_team, :away_team).order(:round, :match_date).to_a
    panel(context, "Partidas (#{matches.size})", 'championship_matches', championship:, matches:, namespace:)
    pools = Bolao::Pool.with_members_count.where(championship:).order(:name).to_a
    panel(context, "Bolões (#{pools.size})", 'championship_pools', championship:, pools:, namespace:)
  end

  def self.team(context, team, namespace)
    players = team.players.order(:name).to_a
    panel(context, "Jogadores (#{players.size})", 'team_players', team:, players:, namespace:)
  end

  def self.panel(context, title, partial, **locals)
    context.instance_exec { panel(title) { render partial: "admin/shared/#{partial}", locals: } }
  end
end
