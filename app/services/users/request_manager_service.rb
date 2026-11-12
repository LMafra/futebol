module Users
  class RequestManagerService
    def self.call(user:, ip_address:) = new(user:, ip_address:).call

    def initialize(user:, ip_address:)
      @user = user
      @ip_address = ip_address
    end

    def call
      @user.with_lock do
        @user.update!(manager_status: :pending)
        Core::AuditLog.create!(action: 'user.manager_requested', user: @user, auditable: @user,
                               ip_address: @ip_address)
      end
      @user
    end
  end
end
