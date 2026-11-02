# /minha-conta: the signed-in user's data (read-only) and the public-profile consent toggle.
class AccountsController < ApplicationController
  before_action { authorize :account }

  def show
    @user = current_user
  end

  def update
    Users::PublicProfileConsentService.call(user: current_user, consent: params[:public_profile_consent] == '1',
                                            ip_address: request.remote_ip)
    redirect_to account_path, notice: 'Preferência salva.', status: :see_other
  end
end
