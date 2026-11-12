# Option lists for /gestor filters and forms, limited by the Gestor:: policy scopes: ActiveAdmin's default
# association filters would list every championship and team, including other managers'.
module GestorHelper
  def gestor_championships
    Gestor::Core::ChampionshipPolicy::Scope.new(current_user, Core::Championship.all).resolve.order(:name, :season)
  end

  def gestor_teams = gestor_team_scope.resolve.order(:name)

  # Index rows link to edit only teams the manager may edit; asking the policy row by row would be an N+1.
  def gestor_team_editable?(team) = !(@gestor_locked_team_ids ||= gestor_team_scope.locked_ids).include?(team.id)

  private

  def gestor_team_scope = Gestor::Core::TeamPolicy::Scope.new(current_user, Core::Team.all)
end
