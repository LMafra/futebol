# TODO: TICKET-0010 — wire into ActiveAdmin
class AuditLogPolicy < ApplicationPolicy
  def create? = false
  def update? = false
  def destroy? = false
end
