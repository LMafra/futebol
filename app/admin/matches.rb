ActiveAdmin.register Core::Match, as: 'Match' do
  menu parent: 'Partidas', label: 'Partidas', priority: 1

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

  index do
    id_column
    column('Partida') { |match| link_to match.to_s, admin_match_path(match) }
    column :championship
    column :match_date
    column('Placar', class: 'tabular-nums') { |match| admin_score(match) }
    column(:status) { |match| admin_match_status_badge(match) }
    column :scores_calculated_at
    actions do |match|
      next unless authorized?(:preview, match)

      text_node admin_icon_action_link('Preview', admin_bolaopreview_path(match_id: match.id), :preview)
    end
  end

  action_item :preview, only: :show, if: -> { authorized?(:preview, resource) } do
    link_to 'Preview do Bolão', admin_bolaopreview_path(match_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  scouts_open = -> { authorized?(:record_scouts, resource) && (!resource.scheduled? || resource.may_start_match?) }
  action_item :scouts, only: :show, if: scouts_open do
    link_to 'Scouts', admin_matchscouts_path(match_id: resource.id),
            class: admin_match_step_classes(resource, :scouts)
  end

  action_item :finalize, only: :show,
                         if: -> { authorized?(:finalize, resource) && (resource.live? || resource.may_start_match?) } do
    link_to 'Finalizar', admin_matchfinalizer_path(match_id: resource.id),
            class: admin_match_step_classes(resource, :finalize)
  end

  action_item :revert, only: :show, if: -> { authorized?(:revert, resource) && resource.may_revert_match? } do
    link_to 'Reverter pontuação', admin_matchreversal_path(match_id: resource.id),
            class: AdminHelper::ADMIN_DANGER_BUTTON_CLASSES
  end

  action_item :history, only: :show do
    link_to 'Histórico', admin_audithistory_path(match_id: resource.id),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end

  show title: :to_s do
    attributes_table do
      row :championship
      row :home_team
      row :away_team
      row :match_date
      row('Rodada', &:round)
      row('Placar') { |match| admin_score(match) }
      row(:status) { |match| admin_match_status_badge(match) }
      row :scores_calculated_at
      row :scoring_token
      row :reversal_token
      row :external_id
    end
  end
end
