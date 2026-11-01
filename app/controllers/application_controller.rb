class ApplicationController < ActionController::Base
  include Authentication
  include CurrentUser
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Conditions instead of only:/except: so controllers without an index action don't trip
  # raise_on_missing_callback_actions.
  after_action :verify_authorized, unless: -> { index_action? || active_admin_controller? }
  after_action :verify_policy_scoped, if: -> { index_action? && !active_admin_controller? }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # current_user resumes the cookie session first, so Current.user is set even on unauthenticated-access actions.
  def pundit_user = current_user

  private

  def index_action? = action_name == 'index'

  # ActiveAdmin authorizes through its own adapter (TICKET-0010), which Pundit's verification does not see.
  def active_admin_controller? = is_a?(ActiveAdmin::BaseController)

  def user_not_authorized
    respond_to do |format|
      format.json { render json: { error: 'forbidden' }, status: :forbidden }
      format.any { redirect_back_or_to main_app.root_path, alert: 'Você não tem permissão para esta ação.' }
    end
  end

  # ActiveAdmin config.authentication_method.
  def authenticate_admin_user!
    return request_authentication unless authenticated?
    return if current_user&.admin?

    render_forbidden(Pundit::NotAuthorizedError.new('admin required'))
  end

  # ActiveAdmin denials (config.on_unauthorized_access): a redirect would loop back into the admin.
  def render_forbidden(exception, message: nil)
    Rails.logger.warn("forbidden #{controller_path}##{action_name} user_id=#{current_user&.id}: #{exception.message}")
    respond_to do |format|
      format.json { render json: { error: 'forbidden' }, status: :forbidden }
      format.any do
        render 'errors/forbidden', layout: 'application', formats: :html, status: :forbidden, locals: { message: }
      end
    end
  end
end
