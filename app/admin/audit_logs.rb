ActiveAdmin.register Core::AuditLog, as: 'AuditLog' do
  menu false

  actions :index, :show
  includes :user
  config.sort_order = 'created_at_desc'

  filter :action, label: 'Ação', as: :select, collection: -> { admin_audit_log_options(:action) }
  filter :user, label: 'Quem'
  filter :auditable_type, label: 'Tipo de registro', as: :select,
                          collection: -> { admin_audit_log_options(:auditable_type) }
  filter :created_at, label: 'Quando'

  AdminCollectionIndex.register(self, 'admin/listings/audit_logs')

  show do
    attributes_table do
      row :action
      row :user
      row(:auditable) { |log| "#{log.auditable_type} ##{log.auditable_id}" if log.auditable_type }
      row(:ip_address) { |log| log.ip_address.to_s }
      row(:metadata) { |log| pre JSON.pretty_generate(log.metadata) }
      row :created_at
    end
  end
end
