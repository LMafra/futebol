ActiveAdmin.register Core::Team, as: 'Team' do
  menu parent: 'Cadastros', label: 'Times'

  permit_params :name, :short_name, :crest_url, :external_id

  filter :name
  filter :short_name
  filter :external_id

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
