ActiveAdmin.register Core::Championship, as: 'Championship', namespace: :gestor do
  menu parent: 'Meus campeonatos', label: 'Campeonatos', priority: 1

  permit_params :name, :season, :logo, :remove_logo, :private, :cartola_goalkeeper_limit, :cartola_defender_limit,
                :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget, :cartola_base_player_value,
                :prize_description, :kind, :gender, :category, :level, *Core::Championship::PRIZE_PLACES

  actions :index, :show, :new, :create, :edit, :update

  AdminNameSearch.register(self)
  AdminChampionshipEnrollment.register(self)
  filter :season, as: :select, collection: -> { admin_season_options }
  filter :status, label: 'Situação', as: :select, collection: [%w[Rascunho draft], %w[Publicado published]]

  index do
    id_column
    column :name
    column :season
    column('Privado') { |championship| status_tag(championship.private? ? 'sim' : 'não') }
    column('Situação') { |championship| status_tag(championship.draft? ? 'rascunho' : 'publicado') }
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

  action_item :continue_draft, only: :show, if: -> { resource.draft? && authorized?(:update, resource) } do
    link_to 'Continuar rascunho', edit_gestor_championship_path(resource, step: 'revisao'),
            class: AdminHelper::ADMIN_BUTTON_CLASSES
  end

  action_item :new_pool, only: :show, if: -> { authorized?(:create, Bolao::Pool.new(championship: resource)) } do
    link_to 'Criar bolão', new_gestor_pool_path(pool: { championship_id: resource.id }),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  show title: :to_s do
    attributes_table do
      row :name
      row :season
      row :external_id
      row('Modalidade', &:modality_label)
      row('Situação') { |championship| championship.draft? ? 'Rascunho (não aparece no site)' : 'Publicado' }
      row('Campeonato privado?') { |championship| championship.private? ? 'Sim' : 'Não' }
      row('Logo') { |championship| championship_logo(championship, variant: :medium, size: 'size-24') }
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

  form html: { multipart: true } do |f|
    AdminChampionshipForm.render(self, f, namespace: :gestor)
  end

  controller do
    include GestorResource
    include ChampionshipWizardActions

    before_build do |championship|
      championship.manager = current_user if current_user.manager?
      assign_external_id(championship)
    end
  end
end
