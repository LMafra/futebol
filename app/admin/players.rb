ActiveAdmin.register Core::Player, as: 'Player' do
  menu parent: 'Cadastros', label: 'Jogadores'

  permit_params :team_id, :name, :position, :shirt_number, :base_value, :external_id
  includes :team

  filter :team
  filter :name
  filter :position, as: :select, collection: -> { Core::Player::POSITIONS }
  filter :external_id

  index do
    selectable_column
    id_column
    column :name
    column :team
    column :position
    column :shirt_number
    column('Valor base') { |player| player.base_value ? format('C$ %.2f', player.base_value) : 'padrão do campeonato' }
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :team
      f.input :name
      f.input :position, as: :select, collection: Core::Player::POSITIONS
      f.input :shirt_number
      f.input :base_value, label: 'Valor base (C$)', hint: 'Em branco: o valor base do campeonato no Cartola.',
                           input_html: { min: 0, step: '0.01' }
      f.input :external_id
    end
    f.actions
  end
end
