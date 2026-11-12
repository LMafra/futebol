class ManagerRequestMailer < ApplicationMailer
  def approved
    @user = params[:user]
    mail subject: 'Seu pedido de gestor foi aprovado', to: @user.email_address
  end

  def rejected
    @user = params[:user]
    mail subject: 'Seu pedido de gestor não foi aprovado', to: @user.email_address
  end
end
