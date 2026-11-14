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
    # Bulk actions of the list (AdminBulkActions): the policy scope picks the matches; only scheduled ones change.
    def bulk_reschedule? = index?
    def bulk_destroy? = index?

    # The public page (/partidas/:id): matches of published championships; of a private one, only to the members
    # of its bolões, its manager and the admins.
    def public_show?
      championship = record.championship
      return false unless championship.published?

      !championship.private? || admin? || manages?(championship) || pool_member?(championship)
    end

    private

    def pool_member?(championship)
      user.present? &&
        Bolao::PoolMembership.joins(:pool).exists?(user:, bolao_pools: { championship_id: championship.id })
    end

    class Scope < ApplicationPolicy::Scope
      private

      def managed_scope = scope.where(championship_id: managed_championships.select(:id))
    end
  end
end
