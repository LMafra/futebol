class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized
  include AuthRateLimiting

  limit_auth_attempts

  def new
    @user = Core::User.new
  end

  def create
    @user = Core::User.new(user_params)

    if @user.save
      start_new_session_for @user
      grant_public_profile_consent if params.dig(:user, :public_profile_consent) == '1'
      redirect_to root_path, notice: 'Conta criada'
    else
      @public_profile_consent = params.dig(:user, :public_profile_consent) == '1'
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: %i[name email_address password password_confirmation])
  end

  def grant_public_profile_consent
    Users::PublicProfileConsentService.call(user: @user, consent: true, ip_address: request.remote_ip)
  end
end
