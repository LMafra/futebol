ActiveAdmin.register Core::Match, as: 'Match' do
  menu parent: 'Campeonatos', label: 'Partidas', priority: 2
  breadcrumb { match_resource_crumbs }

  actions :index, :show
  includes :home_team, :away_team, :championship
  config.sort_order = 'match_date_desc'

  filter :championship
  filter :round, label: 'Rodada', as: :select, collection: -> { admin_round_options }
  filter :status, as: :select, collection: -> { admin_match_status_options }
  filter :external_id_eq, label: 'ID externo', as: :string
  filter :match_date

  scope :all, default: true
  scope('Encerradas sem pontuação') { |matches| matches.where(status: 'finished', scores_calculated_at: nil) }
  scope('Pontuadas') { |matches| matches.where(status: 'scored') }

  AdminCollectionIndex.register(self, 'admin/listings/matches')
  AdminBulkActions.register(self, :destroy, :reschedule)

  action_item :preview, only: :show, if: -> { authorized?(:preview, resource) } do
    link_to 'Preview do Bolão', admin_bolaopreview_path(match_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  action_item :revert, only: :show, if: -> { authorized?(:revert, resource) && resource.may_revert_match? } do
    link_to 'Reverter pontuação', admin_matchreversal_path(match_id: resource.id),
            class: AdminHelper::ADMIN_DANGER_BUTTON_CLASSES
  end

  action_item :history, only: :show do
    link_to 'Histórico', admin_audithistory_path(match_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  AdminMatchBoard.register(self) do
    panel 'Dados técnicos' do
      attributes_table_for(resource, :scores_calculated_at, :scoring_token, :reversal_token, :external_id)
    end
  end
end
