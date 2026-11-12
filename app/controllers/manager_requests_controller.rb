class ManagerRequestsController < ApplicationController
  before_action { authorize :manager_request }
  before_action :redirect_if_already_requested, only: %i[new create]

  def new; end

  def create
    Users::RequestManagerService.call(user: current_user, ip_address: request.remote_ip)
    redirect_to account_path, notice: 'Pedido enviado. Você recebe um e-mail quando um administrador decidir.',
                              status: :see_other
  end

  private

  def redirect_if_already_requested
    return unless current_user.admin? || current_user.manager? || current_user.manager_pending?

    redirect_to account_path, notice: manager_request_redirect_notice, status: :see_other
  end

  def manager_request_redirect_notice
    if current_user.manager_pending?
      'Seu pedido de gestor já está em análise.'
    else
      'Você já tem acesso de gestor.'
    end
  end
end
