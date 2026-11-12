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
      row(:manager_status) { |user| I18n.t("activerecord.enums.core/user.manager_status.#{user.manager_status}") }
      row :active
      row :created_at
    end
  end

  member_action :approve_manager, method: :put do
    authorize! :approve_manager, resource
    Users::ReviewManagerRequestService.call(user: resource, decision: :approved, actor: current_user,
                                            ip_address: request.remote_ip)
    redirect_to admin_user_path(resource), notice: 'Gestor aprovado.', status: :see_other
  end

  member_action :reject_manager, method: :put do
    authorize! :reject_manager, resource
    Users::ReviewManagerRequestService.call(user: resource, decision: :rejected, actor: current_user,
                                            ip_address: request.remote_ip)
    redirect_to admin_user_path(resource), notice: 'Pedido recusado.', status: :see_other
  end

  action_item :approve_manager, only: :show, if: proc { resource.manager_pending? } do
    link_to 'Aprovar gestor', approve_manager_admin_user_path(resource),
            data: { turbo_method: :put, turbo_confirm: 'Aprovar este pedido de gestor?' },
            class: 'action-item-button'
  end

  action_item :reject_manager, only: :show, if: proc { resource.manager_pending? } do
    link_to 'Recusar pedido', reject_manager_admin_user_path(resource),
            data: { turbo_method: :put, turbo_confirm: 'Recusar este pedido de gestor?' },
            class: 'action-item-button'
  end
end
