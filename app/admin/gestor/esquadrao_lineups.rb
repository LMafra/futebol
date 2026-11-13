ActiveAdmin.register Cartola::Lineup, as: 'EsquadraoLineup', namespace: :gestor do
  menu parent: 'Configurações', label: 'Escalações', priority: 3

  actions :index, :show
  includes :squad, :championship

  filter :championship, collection: -> { gestor_championships }
  filter :round, label: 'Rodada', as: :select, collection: -> { admin_round_options }

  index do
    id_column
    column :championship
    column :squad
    column :round, class: 'text-right tabular-nums'
    column :formation
    actions defaults: false do |lineup|
      text_node admin_icon_action_link('Ver', gestor_esquadrao_lineup_path(lineup), :view)
    end
  end

  show do
    attributes_table do
      row :championship
      row :squad
      row :round
      row :formation
      row('Capitão') { |lineup| lineup.captain&.name }
    end
    panel 'Jogadores' do
      table_for resource.selected_players do
        column :name
        column :position
        column(:team) { |player| player.team.name }
      end
    end
  end
end
