ActiveAdmin.register Core::Match, as: 'Match' do
  menu priority: 2, label: 'Partidas'

  actions :index, :show
  includes :home_team, :away_team, :championship
  config.sort_order = 'match_date_desc'

  filter :championship
  filter :status, as: :select, collection: -> { Core::Match::STATUSES }
  filter :external_id
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
    column(:status) { |match| status_tag match.status }
    column :scores_calculated_at
    actions
  end

  show title: :to_s do
    attributes_table do
      row :championship
      row :home_team
      row :away_team
      row :match_date
      row('Placar') { |match| admin_score(match) }
      row(:status) { |match| status_tag match.status }
      row :scores_calculated_at
      row :scoring_token
      row :reversal_token
      row :external_id
    end
  end
end
