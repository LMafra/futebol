ActiveAdmin.register Core::Championship, as: 'Championship', namespace: :gestor do
  menu parent: 'Campeonatos', label: 'Campeonatos', priority: 1

  permit_params :name, :season, :logo, :remove_logo, :private, :cartola_goalkeeper_limit, :cartola_defender_limit,
                :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget, :cartola_base_player_value,
                :prize_description, :kind, :gender, :category, :level, *Core::Championship::PRIZE_PLACES

  actions :index, :show, :new, :create, :edit, :update

  AdminNameSearch.register(self)
  AdminChampionshipEnrollment.register(self)
  filter :season, as: :select, collection: -> { admin_season_options }
  filter :status, label: 'Situação', as: :select, collection: [%w[Rascunho draft], %w[Publicado published]]

  includes logo_attachment: :blob
  AdminCollectionIndex.register(self, 'admin/listings/championships')

  action_item :new_match, only: :show, if: -> { authorized?(:enroll, resource) && resource.teams.many? } do
    safe_join([modal_trigger('Agendar partida', :match, new_gestor_match_path(match: { championship_id: resource.id }),
                             classes: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES),
               render('admin/modals/match', championship: resource)])
  end

  action_item :continue_draft, only: :show, if: -> { resource.draft? && authorized?(:update, resource) } do
    link_to 'Continuar rascunho', edit_gestor_championship_path(resource, step: 'revisao'),
            class: AdminHelper::ADMIN_BUTTON_CLASSES
  end

  action_item :new_pool, only: :show, if: -> { authorized?(:create, Bolao::Pool.new(championship: resource)) } do
    safe_join([modal_trigger('Criar bolão', :pool, new_gestor_pool_path(pool: { championship_id: resource.id }),
                             classes: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES),
               render('admin/modals/pool', championship: resource, namespace: :gestor)])
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
    AdminRecordPanels.championship(self, resource, :gestor)
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
