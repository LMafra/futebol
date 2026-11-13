ActiveAdmin.register Core::Championship, as: 'Championship' do
  menu label: 'Campeonatos', priority: 2

  permit_params :name, :season, :logo, :remove_logo, :external_id, :private, :cartola_goalkeeper_limit,
                :cartola_defender_limit, :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget,
                :cartola_base_player_value, :prize_description, *Core::Championship::PRIZE_PLACES

  AdminNameSearch.register(self)
  AdminChampionshipEnrollment.register(self)
  filter :season, as: :select, collection: -> { admin_season_options }
  filter :external_id_eq, label: 'ID externo', as: :string
  filter :private, label: 'Privado'

  index do
    selectable_column
    id_column
    column :name
    column :season
    column :external_id
    column('Privado') { |championship| status_tag(championship.private? ? 'sim' : 'não') }
    actions
  end

  action_item :simulador, only: :show do
    link_to 'Simulador', main_app.simulador_championship_path(resource),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  action_item :esquadrao_rankings, only: :show do
    link_to 'Rankings do Esquadrão', admin_esquadraorankings_path(championship_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  show title: :to_s do
    attributes_table do
      row :name
      row :season
      row :external_id
      row('Campeonato privado?') { |championship| championship.private? ? 'Sim' : 'Não' }
      row('Logo') { |championship| championship_logo(championship, variant: :medium, size: 'size-24') }
    end
    AdminChampionshipEnrollment.panel(self, resource, :admin)
    panel 'Esquadrão' do
      attributes_table_for resource do
        row('Limite de goleiros', &:cartola_goalkeeper_limit)
        row('Limite de defensores', &:cartola_defender_limit)
        row('Limite de meio-campistas', &:cartola_midfielder_limit)
        row('Limite de atacantes', &:cartola_forward_limit)
        row('Orçamento inicial') { |championship| format('C$ %.2f', championship.cartola_initial_budget) }
        row('Valor base do jogador') { |championship| format('C$ %.2f', championship.cartola_base_player_value) }
      end
    end
    active_admin_comments_for resource
  end

  form html: { multipart: true,
               data: { controller: 'form-wizard', action: 'keydown->form-wizard#submitOrAdvance' } } do |f|
    f.semantic_errors
    text_node championship_wizard_nav if f.object.new_record?
    f.inputs 'Dados', data: { form_wizard_target: 'step' } do
      f.input :name
      f.input :season
      f.input :external_id
      AdminImageInput.render(f, :logo, label: 'Logo')
      f.input :private, label: 'Campeonato privado?',
                        hint: 'Campeonatos privados não aparecem na home, na página pública nem no Simulador.'
    end
    f.inputs 'Esquadrão', data: { form_wizard_target: 'step' } do
      f.input :cartola_goalkeeper_limit, label: 'Limite de goleiros', input_html: { min: 0 }
      f.input :cartola_defender_limit, label: 'Limite de defensores', input_html: { min: 0 }
      f.input :cartola_midfielder_limit, label: 'Limite de meio-campistas', input_html: { min: 0 }
      f.input :cartola_forward_limit, label: 'Limite de atacantes', input_html: { min: 0 }
      f.input :cartola_initial_budget, label: 'Orçamento inicial (C$)', input_html: { min: 0, step: '0.01' }
      f.input :cartola_base_player_value, label: 'Valor base do jogador (C$)',
                                          hint: 'Usado para jogadores sem valor base próprio.',
                                          input_html: { min: 0, step: '0.01' }
    end
    f.inputs 'Bolão', data: { form_wizard_target: 'step' } do
      li class: 'input optional' do
        label 'Regras'
        para class: 'inline-hints' do
          text_node 'As regras de pontuação do bolão ficam em '
          a 'Regras do Bolão', href: admin_bolao_scoring_rules_path
          text_node '.'
        end
      end
    end
    f.inputs 'Premiação', data: { form_wizard_target: 'step' } do
      f.input :prize_description, label: 'Descrição geral', input_html: { rows: 3 }
      Core::Championship::PRIZE_PLACES.each do |place|
        f.input place
      end
    end
    text_node championship_wizard_controls if f.object.new_record?
    f.actions
  end

  controller do
    def update
      update! do |success, failure|
        success.html { redirect_to resource_path, notice: 'Campeonato atualizado' }
        failure.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
end
