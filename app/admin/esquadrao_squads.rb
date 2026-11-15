ActiveAdmin.register Cartola::Squad, as: 'EsquadraoSquad' do
  menu parent: 'Participantes', label: 'Times do Esquadrão', priority: 3

  permit_params :name, :user_id
  includes :user

  AdminNameSearch.register(self)

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
