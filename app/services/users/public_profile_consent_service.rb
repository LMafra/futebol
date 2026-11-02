module Users
  # LGPD: the opt-in to show the user's name ("Lucas M.") in public rankings. Only real changes are audited.
  class PublicProfileConsentService
    def self.call(user:, consent:, ip_address:) = new(user:, consent:, ip_address:).call

    def initialize(user:, consent:, ip_address:)
      @user = user
      @consent = consent
      @ip_address = ip_address
    end

    def call
      return @user if @user.public_profile_consented? == @consent

      @user.transaction do
        @user.update!(public_profile_consented_at: @consent ? Time.current : nil)
        Core::AuditLog.create!(action: "user.public_profile_consent_#{@consent ? 'granted' : 'revoked'}",
                               user: @user, auditable: @user, ip_address: @ip_address)
      end
      @user
    end
  end
end
