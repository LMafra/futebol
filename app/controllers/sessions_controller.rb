class SessionsController < ApplicationController
  # Login pages of the restricted areas (/admin/login, /gestor/login): only accounts with that access sign in there.
  AREAS = {
    'admin' => { title: 'Administração', allowed: lambda(&:admin?) },
    'gestor' => { title: 'Área do gestor', allowed: ->(user) { user.admin? || user.manager? } }
  }.freeze

  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized
  include AuthRateLimiting

  limit_auth_attempts

  before_action :set_area, only: %i[new create]

  def new; end

  def create
    user = Core::User.active.authenticate_by(params.permit(:email_address, :password))

    if user.nil?
      redirect_to login_page, alert: 'E-mail ou senha incorretos. Tente novamente.'
    elsif !area_allows?(user)
      redirect_to login_page, alert: "Esta conta não tem acesso à #{@area[:title].downcase}."
    else
      start_new_session_for user
      redirect_to after_authentication_url(area: @area_key)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def set_area
    @area_key = params[:area].presence_in(AREAS.keys)
    @area = AREAS[@area_key]
  end

  def area_allows?(user) = @area.nil? || @area[:allowed].call(user)

  def login_page
    case @area_key
    when 'admin' then admin_login_path
    when 'gestor' then gestor_login_path
    else new_session_path
    end
  end
end
