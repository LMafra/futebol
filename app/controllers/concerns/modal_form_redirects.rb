# Back to the page that opened a <dialog> form (ModalFormHelper): with ?modal=<id> after a validation error, and
# the errors and the typed values in the flash, so the dialog reopens filled in.
module ModalFormRedirects
  private

  # Only paths inside the current namespace: return_to comes from the form.
  def modal_return_path
    path = params[:return_to].to_s
    path if params[:modal].present? && path.start_with?("/#{active_admin_config.namespace.name}/")
  end

  def redirect_back_to_modal(errors, values: {})
    flash[:modal] = { 'id' => params[:modal].to_s, 'values' => values, 'errors' => errors.to_hash,
                      'messages' => errors.full_messages }
    redirect_to "#{modal_return_path}?#{{ modal: params[:modal] }.to_query}", status: :see_other
  end
end
