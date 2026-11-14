module Bulk
  # Approves several pending manager requests, each through Users::ReviewManagerRequestService (AuditLog and e-mail).
  class ApproveManagers
    def self.call(users, actor:, ip_address:)
      report = Report.new(done: %w[aprovado aprovados])
      Bulk.one_by_one { users.each { approve(_1, report, actor:, ip_address:) } }
      report
    end

    def self.approve(user, report, actor:, ip_address:)
      return report.keep!(user, ['não tem pedido pendente', 'não têm pedido pendente']) unless user.manager_pending?

      ::Users::ReviewManagerRequestService.call(user:, decision: :approved, actor:, ip_address:)
      report.done!(user)
    end
  end
end
