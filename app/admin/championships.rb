ActiveAdmin.register Core::Championship, as: 'Championship' do
  menu parent: 'Cadastros', label: 'Campeonatos'

  permit_params :name, :season, :external_id

  filter :name
  filter :season
  filter :external_id

  index do
    selectable_column
    id_column
    column :name
    column :season
    column :external_id
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :season
      f.input :external_id
    end
    f.actions
  end
end
