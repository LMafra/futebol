module Core
  class ChampionshipPolicy < ApplicationPolicy
    def index? = admin? || manager?
    def create? = admin? || manager?
    def show? = admin? || manage?
    def update? = show?
    def destroy? = show?
    def destroy_all? = admin?
    def enroll? = update?
    def unenroll? = update?
    def manage? = record_instance? && manages?(record)
    def public_show? = !record.private?

    class Scope < ApplicationPolicy::Scope
      private

      def managed_scope = scope.managed_by(user)
    end
  end
end
