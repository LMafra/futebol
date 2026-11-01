class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized
  include AuthRateLimiting

  limit_auth_attempts

  def new; end

  def create
    user = Core::User.active.authenticate_by(params.permit(:email_address, :password))

    if user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: 'E-mail ou senha incorretos. Tente novamente.'
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
