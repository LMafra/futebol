module Cartola
  # The squad owner edits and undoes their lineup; an admin may only read it.
  class LineupPolicy < ApplicationPolicy
    def show? = owner? || admin?
    def update? = owner?
    def destroy? = owner? && record.persisted?
    def manage? = record_instance? && manages?(record.championship)
    # Participantes › Esquadrão: the organizer's edit, with a reason (Cartola::LineupCorrection).
    def correct? = admin?

    private

    def owner? = user.present? && record.squad.user_id == user.id
  end
end
