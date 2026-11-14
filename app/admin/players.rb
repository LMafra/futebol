ActiveAdmin.register Core::Player, as: 'Player' do
  menu parent: 'Times', label: 'Jogadores', priority: 2
  breadcrumb { player_resource_crumbs }

  permit_params :team_id, :name, :position, :shirt_number, :base_value, :external_id
  includes :team
  controller { include ModalFormResponses }

  AdminNameSearch.register(self)
  filter :team
  filter :position, as: :select, collection: -> { Core::Player::POSITIONS }
  filter :external_id_eq, label: 'ID externo', as: :string

  AdminCollectionIndex.register(self, 'admin/listings/players')

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :team
      f.input :name
      f.input :position, as: :select, collection: Core::Player::POSITIONS
      f.input :shirt_number
      f.input :base_value, label: 'Valor base (C$)', hint: 'Em branco: o valor base do campeonato no Esquadrão.',
                           input_html: { min: 0, step: '0.01' }
      f.input :external_id
    end
    f.actions
  end
end
