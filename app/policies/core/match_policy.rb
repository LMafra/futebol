module Core
  class MatchPolicy < ApplicationPolicy
    def index? = admin? || manager?
    def show? = admin? || manage?
    def create? = false
    def update? = false
    def destroy? = false
    def manage? = record_instance? && manages?(record.championship)
    def preview? = admin?
    def finalize? = admin?
    def revert? = admin?
    def record_scouts? = admin?
    def record_event? = record_scouts?
    def undo_event? = record_scouts?
    def participation? = record_scouts?

    class Scope < ApplicationPolicy::Scope
      private

      def managed_scope = scope.where(championship_id: managed_championships.select(:id))
    end
  end
end
