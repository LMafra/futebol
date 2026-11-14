ActiveAdmin.register Core::Player, as: 'Player', namespace: :gestor do
  menu parent: 'Times', label: 'Jogadores', priority: 2
  breadcrumb { player_resource_crumbs }

  permit_params :team_id, :name, :position, :shirt_number, :base_value
  includes :team

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource
    include ModalFormResponses

    before_build { |record| assign_external_id(record) }
  end

  AdminNameSearch.register(self)
  filter :team, collection: -> { gestor_teams }
  filter :position, as: :select, collection: -> { Core::Player::POSITIONS }

  AdminCollectionIndex.register(self, 'admin/listings/players')

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :team, collection: gestor_teams
      f.input :name
      f.input :position, as: :select, collection: Core::Player::POSITIONS
      f.input :shirt_number
      f.input :base_value, label: 'Valor base (C$)', hint: 'Em branco: o valor base do campeonato no Esquadrão.',
                           input_html: { min: 0, step: '0.01' }
      f.input :external_id if current_user.admin?
    end
    f.actions
  end
end
