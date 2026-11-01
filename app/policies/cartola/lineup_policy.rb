module Cartola
  # The squad owner edits their lineup; an admin may only read it.
  class LineupPolicy < ApplicationPolicy
    def show? = owner? || admin?
    def update? = owner?

    private

    def owner? = user.present? && record.squad.user_id == user.id
  end
end
