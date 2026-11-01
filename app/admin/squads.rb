ActiveAdmin.register Cartola::Squad, as: 'Squad' do
  menu parent: 'Cartola', label: 'Times do Cartola'

  permit_params :name, :user_id
  includes :user

  filter :name

  index do
    selectable_column
    id_column
    column :name
    column :user
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :user, collection: Core::User.active.order(:email_address)
    end
    f.actions
  end
end
