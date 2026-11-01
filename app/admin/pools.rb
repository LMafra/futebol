ActiveAdmin.register Bolao::Pool, as: 'Pool' do
  menu parent: 'Bolão', label: 'Bolões'

  permit_params :name, :championship_id, :owner_id
  includes :championship, :owner

  filter :name
  filter :championship

  index do
    selectable_column
    id_column
    column :name
    column :championship
    column :owner
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :championship
      f.input :owner, collection: Core::User.active.order(:email_address)
    end
    f.actions
  end
end
