class PasswordsController < ApplicationController
  allow_unauthenticated_access
  skip_after_action :verify_authorized
  before_action :set_user_by_token, only: %i[edit update]
  include AuthRateLimiting

  limit_auth_attempts

  def new; end

  def create
    user = Core::User.find_by(email_address: params[:email_address])
    PasswordsMailer.reset(user).deliver_later if user

    redirect_to new_session_path,
                notice: 'Se houver uma conta com esse e-mail, enviamos as instruções para redefinir a senha.'
  end

  def edit; end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: 'Senha redefinida.'
    else
      redirect_to edit_password_path(params[:token]), alert: 'As senhas não conferem.'
    end
  end

  private

  def set_user_by_token
    @user = Core::User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: 'O link para redefinir a senha é inválido ou expirou.'
  end
end
