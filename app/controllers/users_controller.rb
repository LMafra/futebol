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
      redirect_to root_path, notice: 'Conta criada'
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: %i[name email_address password password_confirmation])
  end
end
