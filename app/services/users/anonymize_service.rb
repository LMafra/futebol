module Users
  # LGPD: strips PII but keeps the row (and its id) so predictions and scores stay in the historical ranking.
  class AnonymizeService
    ANONYMIZED_NAME = 'Usuário anonimizado'.freeze

    def self.call(user:, actor:, ip_address:) = new(user:, actor:, ip_address:).call

    def initialize(user:, actor:, ip_address:)
      @user = user
      @actor = actor
      @ip_address = ip_address
    end

    def call
      @user.with_lock do
        next if @user.anonymized_at?

        @user.sessions.destroy_all
        @user.update!(anonymized_attributes)
        Core::AuditLog.create!(action: 'anonymize', user: @actor, auditable: @user, ip_address: @ip_address)
      end
      @user
    end

    private

    def anonymized_attributes
      {
        name: ANONYMIZED_NAME,
        email_address: "anon-#{SecureRandom.uuid}@invalid",
        cpf: nil,
        password: SecureRandom.hex(32),
        admin: false,
        active: false,
        anonymized_at: Time.current
      }
    end
  end
end
