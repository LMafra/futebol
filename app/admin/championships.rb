ActiveAdmin.register Core::Championship, as: 'Championship' do
  menu parent: 'Cadastros', label: 'Campeonatos'

  permit_params :name, :season, :external_id, :cartola_goalkeeper_limit, :cartola_defender_limit,
                :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget, :cartola_base_player_value

  filter :name
  filter :season
  filter :external_id

  index do
    selectable_column
    id_column
    column :name
    column :season
    column :external_id
    actions
  end

  action_item :cartola_rankings, only: :show do
    link_to 'Rankings do Cartola', admin_cartolarankings_path(championship_id: resource.id),
            class: 'action-item-button'
  end

  show title: :to_s do
    attributes_table do
      row :name
      row :season
      row :external_id
    end
    panel 'Cartola' do
      attributes_table_for resource do
        row('Limite de goleiros', &:cartola_goalkeeper_limit)
        row('Limite de defensores', &:cartola_defender_limit)
        row('Limite de meio-campistas', &:cartola_midfielder_limit)
        row('Limite de atacantes', &:cartola_forward_limit)
        row('Orçamento inicial') { |championship| format('C$ %.2f', championship.cartola_initial_budget) }
        row('Valor base do jogador') { |championship| format('C$ %.2f', championship.cartola_base_player_value) }
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :season
      f.input :external_id
    end
    f.inputs 'Cartola' do
      f.input :cartola_goalkeeper_limit, label: 'Limite de goleiros', input_html: { min: 0 }
      f.input :cartola_defender_limit, label: 'Limite de defensores', input_html: { min: 0 }
      f.input :cartola_midfielder_limit, label: 'Limite de meio-campistas', input_html: { min: 0 }
      f.input :cartola_forward_limit, label: 'Limite de atacantes', input_html: { min: 0 }
      f.input :cartola_initial_budget, label: 'Orçamento inicial (C$)', input_html: { min: 0, step: '0.01' }
      f.input :cartola_base_player_value, label: 'Valor base do jogador (C$)',
                                          hint: 'Usado para jogadores sem valor base próprio.',
                                          input_html: { min: 0, step: '0.01' }
    end
    f.actions
  end
end
