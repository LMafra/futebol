ActiveAdmin.register Core::Championship, as: 'Championship', namespace: :gestor do
  menu parent: 'Meus campeonatos', label: 'Campeonatos', priority: 1

  permit_params :name, :season, :private, :cartola_goalkeeper_limit, :cartola_defender_limit,
                :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget, :cartola_base_player_value,
                :prize_description, *Core::Championship::PRIZE_PLACES

  actions :index, :show, :new, :create, :edit, :update

  AdminNameSearch.register(self)
  AdminChampionshipEnrollment.register(self)
  filter :season, as: :select, collection: -> { admin_season_options }

  index do
    id_column
    column :name
    column :season
    column('Privado') { |championship| status_tag(championship.private? ? 'sim' : 'não') }
    actions defaults: false do |championship|
      text_node admin_icon_action_link('Abrir', gestor_championship_path(championship), :view,
                                       subject: championship.name)
      if authorized?(:update, championship)
        text_node admin_icon_action_link('Editar', edit_gestor_championship_path(championship), :edit,
                                         subject: championship.name)
      end
    end
  end

  action_item :new_match, only: :show, if: -> { authorized?(:enroll, resource) && resource.teams.many? } do
    link_to 'Nova partida', new_gestor_match_path(match: { championship_id: resource.id }),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  show title: :to_s do
    attributes_table do
      row :name
      row :season
      row :external_id
      row('Campeonato privado?') { |championship| championship.private? ? 'Sim' : 'Não' }
    end
    AdminChampionshipEnrollment.panel(self, resource, :gestor)
    panel 'Premiação' do
      attributes_table_for resource do
        row :prize_description
        Core::Championship::PRIZE_PLACES.each do |place|
          row(place) { |championship| championship.public_send(place) }
        end
      end
    end
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
  end

  form html: { data: { controller: 'form-wizard', action: 'keydown->form-wizard#submitOrAdvance' } } do |f|
    f.semantic_errors
    text_node championship_wizard_nav if f.object.new_record?
    f.inputs 'Dados', data: { form_wizard_target: 'step' } do
      f.input :name
      f.input :season
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
          a 'Regras do Bolão', href: gestor_bolao_scoring_rules_path
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
    include GestorResource

    before_build do |championship|
      championship.manager = current_user if current_user.manager?
      assign_external_id(championship)
    end

    def update
      update! do |success, failure|
        success.html { redirect_to resource_path, notice: 'Campeonato atualizado' }
        failure.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
end
