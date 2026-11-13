ActiveAdmin.register Core::AuditLog, as: 'AuditLog' do
  menu false

  actions :index, :show
  includes :user
  config.sort_order = 'created_at_desc'

  filter :action, as: :select, collection: -> { admin_audit_log_options(:action) }
  filter :user
  filter :auditable_type, as: :select, collection: -> { admin_audit_log_options(:auditable_type) }
  filter :created_at

  index do
    id_column
    column(:action) { |log| status_tag(log.action) }
    column :user
    column(:auditable) { |log| admin_auditable_link(log) || "#{log.auditable_type} ##{log.auditable_id}" }
    column(:ip_address, class: 'tabular-nums') { |log| log.ip_address.to_s }
    column :created_at
    actions
  end

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
