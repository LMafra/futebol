ActiveAdmin.register_page 'Dashboard', namespace: :gestor do
  menu priority: 1, label: 'Painel'

  action_item :new_championship do
    link_to 'Novo campeonato', new_gestor_championship_path, class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES,
                                                             data: { role: 'header-cta' }
  end

  content title: 'Painel do gestor' do
    render partial: 'gestor/dashboard/index', locals: {
      overview: assigns[:overview],
      kpis: assigns[:kpis],
      queue: assigns[:queue],
      action_groups: assigns[:action_groups],
      urgency: assigns[:urgency],
      upcoming_matches: assigns[:upcoming_matches]
    }
  end

  controller do
    before_action :load_overview, only: :index

    private

    def load_overview
      championships = helpers.gestor_championships.reorder(season: :desc, name: :asc)
      @overview = Gestor::ChampionshipOverview.call(championships)
      scoped = Core::Match.where(championship_id: championships.map(&:id))
      match_queue = Gestor::MatchQueue.call(scoped)
      @queue = match_queue.items
      @kpis = match_queue.kpis
      @urgency = params[:urgency]
      assign_gestor_action_groups
      @upcoming_matches = upcoming_matches_for(scoped)
    end

    def assign_gestor_action_groups
      @action_groups = Gestor::DashboardActionGroups.call(
        items: @queue, paths: helpers, status_label: ->(status) { helpers.admin_match_status_label(status) }
      )
    end

    def upcoming_matches_for(scoped)
      scoped.includes(:home_team, :away_team)
            .where(status: 'scheduled')
            .where(match_date: Time.current..)
            .order(:match_date)
            .limit(8)
    end
  end
end
