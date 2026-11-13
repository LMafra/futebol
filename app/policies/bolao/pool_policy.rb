module Bolao
  # Shared by the public PoolsController and ActiveAdmin (/admin/pools is gated to admins before Pundit runs).
  class PoolPolicy < ApplicationPolicy
    def index? = signed_in?
    # Only the Gestor (on a championship of his) and the Admin create bolões (ADR 0006); users join by code.
    def create? = admin? || (manager? && (!pool_record? || record.championship.nil? || manages?(record.championship)))
    def join? = signed_in?
    def show? = admin? || (pool_record? && record.member?(user))
    def destroy? = admin? || (pool_record? && record.owned_by?(user))
    def destroy_all? = admin?
    def manage? = record_instance? && manages?(record.championship)

    private

    def signed_in? = user.present?

    # ActiveAdmin authorizes some actions on the class instead of a record.
    def pool_record? = record.is_a?(Bolao::Pool)

    class Scope < ApplicationPolicy::Scope
      def resolve
        return super if user.nil? || user.admin?

        scope.where(id: Bolao::PoolMembership.where(user_id: user.id).select(:pool_id))
      end
    end
  end
end
