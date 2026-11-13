ActiveAdmin.register Core::Player, as: 'Player' do
  menu parent: 'Participantes', label: 'Jogadores'

  permit_params :team_id, :name, :position, :shirt_number, :base_value, :external_id
  includes :team

  AdminNameSearch.register(self)
  filter :team
  filter :position, as: :select, collection: -> { Core::Player::POSITIONS }
  filter :external_id_eq, label: 'ID externo', as: :string

  index do
    selectable_column
    id_column
    column :name
    column :team
    column :position
    column :shirt_number, class: 'text-right tabular-nums'
    column('Valor base', class: 'text-right tabular-nums') do |player|
      player.base_value ? format('C$ %.2f', player.base_value) : 'padrão do campeonato'
    end
    actions
  end

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
