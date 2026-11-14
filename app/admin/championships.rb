ActiveAdmin.register Core::Championship, as: 'Championship' do
  menu parent: 'Campeonatos', label: 'Campeonatos', priority: 1

  permit_params :name, :season, :logo, :remove_logo, :external_id, :private, :cartola_goalkeeper_limit,
                :cartola_defender_limit, :cartola_midfielder_limit, :cartola_forward_limit, :cartola_initial_budget,
                :cartola_base_player_value, :prize_description, :kind, :gender, :category, :level,
                *Core::Championship::PRIZE_PLACES

  AdminNameSearch.register(self)
  AdminChampionshipEnrollment.register(self)
  filter :season, as: :select, collection: -> { admin_season_options }
  filter :status, label: 'Situação', as: :select, collection: [%w[Rascunho draft], %w[Publicado published]]
  filter :external_id_eq, label: 'ID externo', as: :string
  filter :private, label: 'Privado'

  includes logo_attachment: :blob
  AdminCollectionIndex.register(self, 'admin/listings/championships')

  action_item :simulador, only: :show do
    link_to 'Simulador', main_app.simulador_championship_path(resource),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  action_item :esquadrao, only: :show do
    link_to 'Esquadrão', admin_esquadrao_path(championship_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  action_item :continue_draft, only: :show, if: -> { resource.draft? && authorized?(:update, resource) } do
    link_to 'Continuar rascunho', edit_admin_championship_path(resource, step: 'revisao'),
            class: AdminHelper::ADMIN_BUTTON_CLASSES
  end

  action_item :new_pool, only: :show, if: -> { authorized?(:create, Bolao::Pool.new(championship: resource)) } do
    safe_join([modal_trigger('Criar bolão', :pool, new_admin_pool_path(pool: { championship_id: resource.id }),
                             classes: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES),
               render('admin/modals/pool', championship: resource, namespace: :admin)])
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
    AdminRecordPanels.championship(self, resource, :admin)
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

  form html: { multipart: true } do |f|
    AdminChampionshipForm.render(self, f, namespace: :admin)
  end

  controller do
    include ChampionshipWizardActions
  end
end
