# Option lists for /gestor filters and forms, limited by the Gestor:: policy scopes: ActiveAdmin's default
# association filters would list every championship and team, including other managers'.
module GestorHelper
  def gestor_championships
    Gestor::Core::ChampionshipPolicy::Scope.new(current_user, Core::Championship.all).resolve.order(:name, :season)
  end

  def gestor_teams = Gestor::Core::TeamPolicy::Scope.new(current_user, Core::Team.all).resolve.order(:name)

  # A match only takes teams enrolled in its championship: those of the chosen championship, or all of them
  # grouped by championship while none is chosen.
  def gestor_match_team_options(match, attribute)
    selected = match.public_send(:"#{attribute}_id")
    if match.championship
      options_from_collection_for_select(match.championship.teams.order(:name), :id, :name, selected)
    else
      option_groups_from_collection_for_select(gestor_championships.includes(:teams), :teams, :to_s, :id, :name,
                                               selected)
    end
  end

  # Teams of the championship's manager (the admin's when it has none) not enrolled yet, for its page.
  def enrollable_teams(championship)
    Core::Team.where(manager_id: championship.manager_id)
              .where.not(id: championship.championship_teams.select(:team_id)).order(:name)
  end
end
