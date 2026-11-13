module Core
  # Teams belong to one manager (ADR 0006); the admin owns the ones without a manager and sees them all.
  class TeamPolicy < ApplicationPolicy
    def index? = admin? || manager?
    def create? = admin? || manager?
    def show? = admin? || manage?
    def update? = show?
    def destroy? = show?
    def manage? = manager? && record_instance? && record.manager_id == user.id

    class Scope < ApplicationPolicy::Scope
      private

      def managed_scope = scope.owned_by(user)
    end
  end
end
