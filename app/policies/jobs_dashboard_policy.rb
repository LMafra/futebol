# Headless policy for the Solid Queue dashboard mounted at /admin/jobs.
class JobsDashboardPolicy < ApplicationPolicy
  def index? = show?
  def show? = admin?
  def create? = false
  def update? = false
  def destroy? = false
end
