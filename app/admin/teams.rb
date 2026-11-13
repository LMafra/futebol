ActiveAdmin.register Core::Team, as: 'Team' do
  menu parent: 'Participantes', label: 'Times'

  permit_params :name, :short_name, :crest_url, :external_id

  AdminNameSearch.register(self)
  filter :external_id_eq, label: 'ID externo', as: :string

  index do
    selectable_column
    id_column
    column :name
    column :short_name
    column :external_id
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :short_name
      f.input :crest_url
      f.input :external_id
    end
    f.actions
  end
end
