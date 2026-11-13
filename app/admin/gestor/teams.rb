ActiveAdmin.register Core::Team, as: 'Team', namespace: :gestor do
  menu parent: 'Participantes', label: 'Times', priority: 1

  permit_params :name, :short_name, :crest, :remove_crest, :captain_name, :captain_phone

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource

    before_build do |team|
      team.manager = current_user if current_user.manager?
      assign_external_id(team)
    end
  end

  AdminNameSearch.register(self)

  index do
    id_column
    column :name
    column :short_name
    column :captain_name
    actions defaults: false do |team|
      text_node admin_icon_action_link('Abrir', gestor_team_path(team), :view, subject: team.name)
      text_node admin_icon_action_link('Editar', edit_gestor_team_path(team), :edit, subject: team.name)
    end
  end

  show do
    attributes_table do
      row :name
      row :short_name
      row :captain_name
      row(:captain_phone) { |team| formatted_phone(team.captain_phone) }
      row('Escudo') { |team| team_crest(team, variant: :medium, size: 'size-24') }
      row :external_id
      row('Campeonatos') do |team|
        links = team.championships.order(:name).map do |championship|
          link_to championship, gestor_championship_path(championship), class: inline_link_classes('font-body')
        end
        safe_join(links, ', ')
      end
    end
  end

  form html: { multipart: true } do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :short_name
      AdminImageInput.render(f, :crest, label: 'Escudo')
      f.input :external_id if current_user.admin?
    end
    f.inputs 'Capitão' do
      f.input :captain_name, hint: 'Contato do time; não precisa ter conta no Craquefy.'
      f.input :captain_phone, as: :phone, hint: 'Com DDD, ex. (11) 98765-4321.',
                              input_html: { autocomplete: 'tel-national', inputmode: 'tel' }
    end
    f.actions
  end
end
