module Admin
  # Builds Action Center groups for the /admin dashboard.
  class DashboardActionGroups
    def self.call(live:, pending:, manager_queue:, paths:)
      new(live:, pending:, manager_queue:, paths:).call
    end

    def initialize(live:, pending:, manager_queue:, paths:)
      @live = live
      @pending = pending
      @manager_queue = manager_queue
      @paths = paths
    end

    def call
      {
        critical: @live.limit(5).map { |match| live_item(match) },
        high: @pending.limit(5).map { |match| pending_item(match) },
        medium: @manager_queue.first(5).map { |entry| manager_item(entry) }
      }
    end

    private

    def live_item(match)
      {
        id: "live-#{match.id}",
        title: match.to_s,
        context: "Ao vivo · #{I18n.l(match.match_date, format: '%d/%m %H:%M')}",
        action_text: 'Finalizar partida',
        action_path: @paths.admin_match_path(match, modal: 'finalize')
      }
    end

    def pending_item(match)
      {
        id: "pending-#{match.id}",
        title: match.to_s,
        context: 'Encerrada sem pontuação',
        action_text: 'Finalizar e Pontuar Partida',
        action_path: @paths.admin_match_path(match, modal: 'finalize')
      }
    end

    def manager_item(entry)
      {
        id: "manager-#{entry.user.id}",
        title: entry.user.name,
        context: "Pedido de gestor · #{entry.user.email_address}",
        action_text: 'Ver pedido',
        action_path: @paths.admin_user_path(entry.user)
      }
    end
  end
end
