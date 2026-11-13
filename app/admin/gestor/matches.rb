ActiveAdmin.register Core::Match, as: 'Match', namespace: :gestor do
  menu parent: 'Campeonatos', label: 'Partidas', priority: 2
  breadcrumb { match_resource_crumbs }

  actions :index, :show, :new, :create, :edit, :update
  permit_params do
    attributes = %i[home_team_id away_team_id match_date round]
    %w[new create].include?(action_name) ? [:championship_id, *attributes] : attributes
  end
  includes :home_team, :away_team, :championship
  config.sort_order = 'match_date_desc'

  filter :championship, collection: -> { gestor_championships }
  filter :round, label: 'Rodada', as: :select, collection: -> { admin_round_options }
  filter :status, as: :select, collection: -> { admin_match_status_options }
  filter :match_date

  before_build do |match|
    assign_external_id(match)
    load_teams(match)
  end

  index do
    id_column
    column('Partida') { |match| link_to match.to_s, gestor_match_path(match) }
    column :championship
    column('Rodada', class: 'text-right tabular-nums', &:round)
    column :match_date
    column('Placar', class: 'tabular-nums') { |match| admin_score(match) }
    column(:status) { |match| admin_match_status_badge(match) }
    actions defaults: false do |match|
      text_node admin_icon_action_link('Abrir', gestor_match_path(match), :view, subject: match.to_s)
      if match.scheduled?
        text_node admin_icon_action_link('Editar', edit_gestor_match_path(match), :edit, subject: match.to_s)
      end
    end
  end

  action_item :revert, only: :show, if: -> { authorized?(:revert, resource) && resource.may_revert_match? } do
    link_to 'Reverter pontuação', scoring_path('matchreversal', match_id: resource.id),
            class: AdminHelper::ADMIN_DANGER_BUTTON_CLASSES
  end

  AdminMatchBoard.register(self)

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :championship, collection: gestor_championships, include_blank: false if f.object.new_record?
      f.input :home_team, collection: gestor_match_team_options(f.object, :home_team),
                          hint: ('Só times inscritos no campeonato.' if f.object.new_record?)
      f.input :away_team, collection: gestor_match_team_options(f.object, :away_team)
      f.input :match_date, as: :datetime_picker,
                           hint: 'Depois de agendar, registre os lances e finalize na página da partida.'
      f.input :round, label: 'Rodada', input_html: { min: 1 }
    end
    f.actions if f.object.new_record? || f.object.scheduled?
  end

  controller do
    include GestorResource
    include ModalFormResponses

    private

    def load_teams(match)
      teams = Core::Team.where(id: [match.home_team_id, match.away_team_id].compact).index_by(&:id)
      match.home_team = teams[match.home_team_id] if teams.key?(match.home_team_id)
      match.away_team = teams[match.away_team_id] if teams.key?(match.away_team_id)
    end
  end
end
