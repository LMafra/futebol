# Headless (authorize :account): every signed-in user manages their own account.
class AccountPolicy < ApplicationPolicy
  def show? = user.present?
  def update? = user.present?
end
