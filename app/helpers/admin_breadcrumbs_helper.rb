# Breadcrumbs of /admin and /gestor follow the navigation tree (ADR 0006), not the URL: a match sits under its
# championship (Campeonatos › campeonato › Partidas), a player under his team (Times › time › Jogadores).
# Used by the `breadcrumb` blocks of the resources and custom pages; the current page is the title, not a crumb.
module AdminBreadcrumbsHelper
  def championship_crumbs(championship)
    crumbs = [namespace_crumb, [Core::Championship.model_name.human(count: 2), crumb_path(:championships)]]
    crumbs << [championship.to_s, crumb_path(:championship, championship)] if championship&.persisted?
    breadcrumb_links(crumbs)
  end

  def match_crumbs(match = nil, championship: match&.championship)
    matches = [Core::Match.model_name.human(count: 2), crumb_path(:matches, q: championship_filter(championship))]
    links = championship_crumbs(championship) + breadcrumb_links([matches])
    links += breadcrumb_links([[match.to_s, crumb_path(:match, match)]]) if match&.persisted? && action_name != 'show'
    links
  end

  def team_crumbs(team)
    crumbs = [namespace_crumb, [Core::Team.model_name.human(count: 2), crumb_path(:teams)]]
    crumbs << [team.to_s, crumb_path(:team, team)] if team&.persisted?
    breadcrumb_links(crumbs)
  end

  def player_crumbs(player = nil, team: player&.team)
    players = [Core::Player.model_name.human(count: 2), crumb_path(:players, q: team && { team_id_eq: team.id })]
    links = team_crumbs(team) + breadcrumb_links([players])
    return links unless player&.persisted? && action_name != 'show'

    links + breadcrumb_links([[player.to_s, crumb_path(:player, player)]])
  end

  # For the matches and players resources: the record, or the championship/team picked in the form or filter.
  def match_resource_crumbs
    match = resource if params[:id]
    championship = match&.championship || scoped_find(Core::Championship, params.dig(:match, :championship_id),
                                                      params.dig(:q, :championship_id_eq))
    crumbs = match_crumbs(match, championship:)
    action_name == 'index' ? crumbs[0..-2] : crumbs
  end

  def player_resource_crumbs
    player = resource if params[:id]
    team = player&.team || scoped_find(Core::Team, params.dig(:player, :team_id), params.dig(:q, :team_id_eq))
    crumbs = player_crumbs(player, team:)
    action_name == 'index' ? crumbs[0..-2] : crumbs
  end

  private

  def scoped_find(model, *ids)
    id = ids.find(&:present?)
    id && active_admin_authorization.scope_collection(model.all).find_by(id:)
  end

  def namespace_crumb
    name = active_admin_namespace.name
    [name == :gestor ? 'Gestor' : 'Admin', public_send(:"#{name}_root_path")]
  end

  def crumb_path(route, *args) = public_send(:"#{active_admin_namespace.name}_#{route}_path", *args.compact)

  def championship_filter(championship) = championship && { championship_id_eq: championship.id }

  def breadcrumb_links(crumbs) = crumbs.map { |label, path| link_to(label, path, class: inline_link_classes) }
end
