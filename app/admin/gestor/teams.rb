ActiveAdmin.register Core::Team, as: 'Team', namespace: :gestor do
  menu parent: 'Participantes', label: 'Times', priority: 1

  permit_params :name, :short_name, :crest_url

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource

    before_build { |record| assign_external_id(record) }
  end

  filter :name
  filter :short_name

  index do
    id_column
    column :name
    column :short_name
    actions defaults: false do |team|
      text_node admin_icon_action_link('Ver', gestor_team_path(team), :view)
      text_node admin_icon_action_link('Editar', edit_gestor_team_path(team), :edit) if gestor_team_editable?(team)
    end
  end

  show do
    attributes_table do
      row :name
      row :short_name
      row :crest_url
      row :external_id
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :short_name
      f.input :crest_url
      f.input :external_id if current_user.admin?
    end
    f.actions if f.object.new_record? || gestor_team_editable?(f.object)
  end
end
