ActiveAdmin.register Core::AuditLog, as: 'AuditLog' do
  menu false

  actions :index, :show
  includes :user
  config.sort_order = 'created_at_desc'

  filter :action
  filter :user
  filter :auditable_type
  filter :created_at

  index do
    id_column
    column :action
    column :user
    column(:auditable) { |log| "#{log.auditable_type} ##{log.auditable_id}" if log.auditable_type }
    column(:ip_address) { |log| log.ip_address.to_s }
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
