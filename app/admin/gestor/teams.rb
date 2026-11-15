ActiveAdmin.register Core::Team, as: 'Team', namespace: :gestor do
  menu parent: 'Times', label: 'Times', priority: 1

  permit_params :name, :short_name, :crest, :remove_crest, :captain_name, :captain_phone

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource
    include ModalFormResponses

    before_build do |team|
      team.manager = current_user if current_user.manager?
      assign_external_id(team)
    end
  end

  action_item :new_player, only: :show, if: -> { authorized?(:create, Core::Player.new(team: resource)) } do
    safe_join([modal_trigger('Cadastrar jogador', :player, new_gestor_player_path(player: { team_id: resource.id }),
                             classes: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES),
               render('admin/modals/player', team: resource, namespace: :gestor)])
  end

  config.remove_action_item(:new)
  action_item :new, only: :index, if: -> { new_action_authorized?(Core::Team) } do
    safe_join([modal_trigger('Novo time', :team, new_gestor_team_path),
               render('admin/modals/team', namespace: :gestor)])
  end

  AdminNameSearch.register(self)

  includes crest_attachment: :blob
  AdminCollectionIndex.register(self, 'admin/listings/teams')
  AdminBulkActions.register(self, :destroy, :enroll)

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
    AdminRecordPanels.team(self, resource, :gestor)
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
