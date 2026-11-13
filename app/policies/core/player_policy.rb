module Core
  class PlayerPolicy < ApplicationPolicy
    def index? = admin? || manager?
    def create? = admin? || (manager? && (!record_instance? || record.team.nil? || team_policy.update?))

    def show? = record_instance? && team_policy.show?
    def update? = record_instance? && team_policy.update?
    def destroy? = record_instance? && team_policy.destroy?

    private

    def team_policy = TeamPolicy.new(user, record.team)

    class Scope < ApplicationPolicy::Scope
      private

      def managed_scope
        team_ids = TeamPolicy::Scope.new(user, Core::Team.all).resolve
        scope.where(team_id: team_ids.select(:id))
      end
    end
  end
end
