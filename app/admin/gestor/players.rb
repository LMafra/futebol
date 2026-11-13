ActiveAdmin.register Core::Player, as: 'Player', namespace: :gestor do
  menu parent: 'Participantes', label: 'Jogadores', priority: 2

  permit_params :team_id, :name, :position, :shirt_number, :base_value
  includes :team

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource

    before_build { |record| assign_external_id(record) }
  end

  AdminNameSearch.register(self)
  filter :team, collection: -> { gestor_teams }
  filter :position, as: :select, collection: -> { Core::Player::POSITIONS }

  index do
    id_column
    column :name
    column(:team) { |player| player.team.name }
    column :position
    column :shirt_number, class: 'text-right tabular-nums'
    actions defaults: false do |player|
      text_node admin_icon_action_link('Abrir', gestor_player_path(player), :view, subject: player.name)
      text_node admin_icon_action_link('Editar', edit_gestor_player_path(player), :edit, subject: player.name)
    end
  end

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
