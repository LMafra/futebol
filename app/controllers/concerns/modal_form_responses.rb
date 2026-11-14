# Creation from a <dialog> (ModalFormHelper) in /admin and /gestor: success goes back to the page that opened the
# dialog, validation errors reopen it there (ModalFormRedirects). From the full "new" page only the notice changes.
module ModalFormResponses
  include ModalFormRedirects

  def create
    super do |success, failure|
      success.html { redirect_to modal_return_path || resource_path, notice: created_notice }
      failure.html { redirect_back_to_modal(resource.errors, values: modal_values) } if modal_return_path
    end
  end

  private

  def created_notice
    t("modal_forms.#{controller_name}.created", name: resource.to_s, code: resource.try(:code), default: nil)
  end

  # Typed text only: an upload can't travel in the flash and is chosen again.
  def modal_values = permitted_params[resource_request_name].to_h.select { |_, value| value.is_a?(String) }
end
