ActiveAdmin.register Core::Player, as: 'Player' do
  menu parent: 'Cadastros', label: 'Jogadores'

  permit_params :team_id, :name, :position, :shirt_number, :external_id
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
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :team
      f.input :name
      f.input :position, as: :select, collection: Core::Player::POSITIONS
      f.input :shirt_number
      f.input :external_id
    end
    f.actions
  end
end
