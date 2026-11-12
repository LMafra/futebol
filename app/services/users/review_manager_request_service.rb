module Users
  class ReviewManagerRequestService
    CHANGES = {
      approved: { role: :manager, manager_status: :approved },
      rejected: { manager_status: :rejected }
    }.freeze

    def self.call(user:, decision:, actor:, ip_address:) = new(user:, decision:, actor:, ip_address:).call

    def initialize(user:, decision:, actor:, ip_address:)
      @user = user
      @decision = decision.to_sym
      @actor = actor
      @ip_address = ip_address
    end

    def call
      @user.with_lock do
        @user.update!(CHANGES.fetch(@decision))
        Core::AuditLog.create!(action: "user.manager_#{@decision}", user: @actor, auditable: @user,
                               ip_address: @ip_address)
      end
      ManagerRequestMailer.with(user: @user).public_send(@decision).deliver_later
      @user
    end
  end
end
