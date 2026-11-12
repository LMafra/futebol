module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Core::Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  # The page that asked for the login wins; otherwise the area of the login page, then the user's own area.
  def after_authentication_url(area: nil)
    session.delete(:return_to_after_authenticating) || area_root_url(area || home_area_of(Current.user))
  end

  def home_area_of(user)
    if user&.admin? then 'admin'
    elsif user&.manager? then 'gestor'
    end
  end

  def area_root_url(area)
    case area.to_s
    when 'admin' then admin_root_url
    when 'gestor' then gestor_root_url
    else root_url
    end
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
