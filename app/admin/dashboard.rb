ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: 'Painel de pontuação' do
    render partial: 'admin/dashboard/scoring', locals: {
      live: assigns[:live], pending: assigns[:pending], recent_logs: assigns[:recent_logs],
      metrics_counts: assigns[:metrics_counts]
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
      @metrics_counts = metric_counts
    end

    def recent_audit_logs
      active_admin_authorization.scope_collection(Core::AuditLog.all)
                                .includes(:user).order(created_at: :desc).limit(8)
    end

    def metric_counts
      { championships: Core::Championship.count, teams: Core::Team.count,
        players: Core::Player.count, matches: Core::Match.count }
    end
  end
end
