# Headless (authorize :users_dashboard): signed-in users see their personal area.
class UsersDashboardPolicy < ApplicationPolicy
  def show? = user.present?
end
