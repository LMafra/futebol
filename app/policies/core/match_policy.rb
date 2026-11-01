module Core
  # Matches come from the CSV import and change state only through the admin flows
  # (finalize, revert), never through plain create/update/destroy.
  class MatchPolicy < ApplicationPolicy
    def create? = false
    def update? = false
    def destroy? = false

    def preview? = admin?
    def finalize? = admin?
    def revert? = admin?
  end
end
