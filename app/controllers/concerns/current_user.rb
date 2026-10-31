module CurrentUser
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    resume_session
    Current.user
  end

  def user_signed_in? = current_user.present?

  def authenticate_admin_user!
    redirect_to main_app.root_path, alert: 'Acesso restrito a administradores.' unless current_user&.admin?
  end

  def set_current_request_details
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end
end
