# Shared by ActiveAdmin resources under /gestor: re-authorize after assigning params on update (so a manager
# cannot move a record into a foreign championship), and generate external ids when creating.
module GestorResource
  extend ActiveSupport::Concern

  def update_resource(object, attributes)
    object.assign_attributes(*attributes)
    authorize_resource! object
    super
  end

  private

  def assign_external_id(record)
    return unless record.respond_to?(:external_id=)
    return if record.external_id.present?

    record.external_id = "gestor-#{SecureRandom.uuid}"
  end
end
