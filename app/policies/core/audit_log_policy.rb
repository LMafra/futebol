module Core
  # Read-only: audit entries are written by services, never through the admin.
  class AuditLogPolicy < ApplicationPolicy
    def create? = false
    def update? = false
    def destroy? = false
  end
end
