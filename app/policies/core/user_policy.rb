module Core
  class UserPolicy < ApplicationPolicy
    def create? = false
    def update? = false
    def destroy? = false
    def approve_manager? = admin? && record.manager_pending?
    def reject_manager? = admin? && record.manager_pending?
    def bulk_approve_manager? = admin?
  end
end
