ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  action_item :new_championship do
    link_to 'Criar campeonato', new_admin_championship_path, class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES,
                                                             data: { role: 'header-cta' }
  end

  content title: 'Painel de pontuação' do
    render partial: 'admin/dashboard/scoring', locals: {
      live: assigns[:live], pending: assigns[:pending], recent_logs: assigns[:recent_logs],
      metrics_counts: assigns[:metrics_counts], recent_matches: assigns[:recent_matches],
      manager_queue: assigns[:manager_queue]
    }
  end

  controller do
    before_action :load_dashboard, only: :index

    private

    def load_dashboard
      matches = Core::Match.includes(:home_team, :away_team).order(:match_date)
      @live = matches.where(status: 'live')
      @pending = matches.where(status: 'finished', scores_calculated_at: nil)
      @recent_logs = recent_audit_logs
      @recent_matches = matches.reorder(match_date: :desc).limit(8)
      @manager_queue = Users::PendingManagerQueue.call
      @metrics_counts = metric_counts
    end

    def recent_audit_logs
      active_admin_authorization.scope_collection(Core::AuditLog.all)
                                .includes(:user).order(created_at: :desc).limit(8)
    end

    # Active = still has a match that is not scored yet (scheduled, live, finished awaiting scoring or reverted).
    def active_championships_count
      Core::Championship.where(id: Core::Match.where.not(status: 'scored').select(:championship_id)).count
    end

    def metric_counts
      {
        active_championships: active_championships_count,
        live_matches: @live.size,
        pending_scoring: @pending.size,
        pending_managers: @manager_queue.size
      }
    end
  end
end
