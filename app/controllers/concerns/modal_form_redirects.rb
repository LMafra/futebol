# Back to the page that opened a <dialog> form (ModalFormHelper): with ?modal=<id> after a validation error, and
# the errors and the typed values in the flash, so the dialog reopens filled in.
module ModalFormRedirects
  private

  # Only paths inside the current namespace: return_to comes from the form.
  def modal_return_path
    path = params[:return_to].to_s
    path if params[:modal].present? && path.start_with?("/#{active_admin_config.namespace.name}/")
  end

  # Without a valid return_to (a form posted from elsewhere) the errors go to `fallback` as an alert.
  def redirect_back_to_modal(errors, values: {}, fallback: nil)
    return redirect_to(fallback, alert: errors.full_messages.to_sentence, status: :see_other) unless modal_return_path

    flash[:modal] = { 'id' => params[:modal].to_s, 'values' => values, 'errors' => errors.to_hash,
                      'messages' => errors.full_messages }
    redirect_to with_modal_param(modal_return_path), status: :see_other
  end

  def with_modal_param(return_path)
    path, query = return_path.split('?', 2)
    "#{path}?#{Rack::Utils.parse_nested_query(query).merge('modal' => params[:modal].to_s).to_query}"
  end
end
