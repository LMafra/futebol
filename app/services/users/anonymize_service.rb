module Users
  # LGPD: strips PII but keeps the row (and its id) so predictions and scores stay in the historical ranking.
  class AnonymizeService
    ANONYMIZED_NAME = 'Usuário anonimizado'.freeze
    REVOKED_ACCESS = { admin: false, role: :user, manager_status: :none, active: false,
                       public_profile_consented_at: nil }.freeze

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
      REVOKED_ACCESS.merge(
        name: ANONYMIZED_NAME,
        email_address: "anon-#{SecureRandom.uuid}#{Core::User::ANONYMIZED_EMAIL_DOMAIN}",
        cpf: nil,
        password: SecureRandom.hex(32),
        anonymized_at: Time.current
      )
    end
  end
end
