ActiveAdmin.register Core::User, as: 'User' do
  menu parent: 'Participantes', label: 'Usuários', priority: 1

  actions :index, :show

  filter :role, as: :select, collection: Core::User.roles.keys
  filter :manager_status, as: :select, collection: Core::User.manager_statuses.keys

  scope :all, default: true
  scope('Pedidos pendentes', :pending) { |users| users.where(manager_status: :pending) }

  index do
    selectable_column
    id_column
    column :name
    column :email_address
    column :role do |user|
      I18n.t("activerecord.enums.core/user.role.#{user.role}")
    end
    column :manager_status do |user|
      I18n.t("activerecord.enums.core/user.manager_status.#{user.manager_status}")
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :email_address
      row(:role) { |user| I18n.t("activerecord.enums.core/user.role.#{user.role}") }
      row(:manager_status) do |user|
        render partial: 'admin/users/manager_status', locals: { user: }
      end
      row :active
      row :created_at
    end
    if resource.manager_pending?
      panel 'Recusar pedido de gestor' do
        render partial: 'admin/users/reject_manager_form', locals: { user: resource, return_to: nil }
      end
    end
  end

  member_action :approve_manager, method: :put do
    authorize! :approve_manager, resource
    Users::ReviewManagerRequestService.call(user: resource, decision: :approved, actor: current_user,
                                            ip_address: request.remote_ip)
    redirect_to manager_review_return_path, notice: "Gestor aprovado: #{resource.name}.", status: :see_other
  end

  member_action :reject_manager, method: :put do
    authorize! :reject_manager, resource
    reason = params[:reason].to_s.strip
    if reason.blank?
      flash[:manager_reject_error] = resource.id
      redirect_to manager_review_return_path, alert: 'Informe o motivo da recusa.', status: :see_other
    else
      Users::ReviewManagerRequestService.call(user: resource, decision: :rejected, actor: current_user,
                                              ip_address: request.remote_ip, reason: reason.first(500))
      redirect_to manager_review_return_path, notice: "Pedido recusado: #{resource.name}.", status: :see_other
    end
  end

  controller do
    private

    def manager_review_return_path
      params[:return_to] == 'dashboard' ? admin_root_path : admin_user_path(resource)
    end
  end

  # The admin importmap has rails-ujs but no Turbo: data-turbo-* attributes are inert here.
  action_item :approve_manager, only: :show, if: proc { resource.manager_pending? } do
    button_to 'Aprovar gestor', approve_manager_admin_user_path(resource),
              method: :put, class: 'action-item-button', data: { confirm: 'Aprovar este pedido de gestor?' }
  end
end
