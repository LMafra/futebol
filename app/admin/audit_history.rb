ActiveAdmin.register_page 'AuditHistory' do
  menu parent: 'Auditoria', label: 'Histórico', priority: 1

  content title: 'Histórico de auditoria' do
    render partial: 'admin/audit_history/list', locals: { logs: assigns[:logs], actions: assigns[:actions] }
  end

  controller do
    before_action :load_logs, only: :index

    private

    def load_logs
      authorize! ActiveAdmin::Auth::READ, Core::AuditLog
      scope = active_admin_authorization.scope_collection(Core::AuditLog.all)
      @actions = scope.distinct.order(:action).pluck(:action)
      @logs = filter(scope).includes(:user).order(created_at: :desc, id: :desc).page(params[:page]).per(50)
    end

    def filter(scope)
      scope = scope.where(action: params[:audit_action]) if params[:audit_action].present?
      scope = scope.where(auditable_type: 'Core::Match', auditable_id: params[:match_id]) if params[:match_id].present?
      scope
    end
  end
end
