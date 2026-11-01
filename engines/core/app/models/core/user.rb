module Core
  class User < ApplicationRecord
    # Users::AnonymizeService rewrites emails into this reserved TLD (RFC 2606); nobody signs up with one.
    ANONYMIZED_EMAIL_DOMAIN = '@invalid'.freeze
    # Shown in public rankings for users who did not opt in (LGPD).
    PUBLIC_FALLBACK_NAME = 'Participante'.freeze

    has_secure_password
    has_many :sessions, class_name: 'Core::Session', dependent: :destroy

    normalizes :email_address, with: ->(email) { email.strip.downcase }
    normalizes :cpf, with: ->(cpf) { cpf.gsub(/\D/, '').presence }

    scope :active, -> { where(active: true) }

    validates :email_address, presence: { message: 'não pode ficar em branco' },
                              uniqueness: { message: 'já está em uso' },
                              format: { with: URI::MailTo::EMAIL_REGEXP, message: 'não é um e-mail válido' }
    validates :password, length: { minimum: 8, message: 'deve ter pelo menos 8 caracteres' }, allow_nil: true
    validates :cpf, format: { with: /\A\d{11}\z/ }, uniqueness: true, allow_nil: true
    # Only on create: accounts made before signup existed (e.g. the seeded admin) may have no name.
    validates :name, presence: { message: 'não pode ficar em branco' }, on: :create
    validate :email_address_not_anonymized, on: :create

    def to_s = email_address

    def public_profile_consented? = public_profile_consented_at.present?

    # First name and last-name initial ("Lucas M."), only with consent.
    def public_display_name
      first_name, *other_names = name.to_s.split
      return PUBLIC_FALLBACK_NAME unless public_profile_consented? && first_name

      [first_name, other_names.last&.then { |last_name| "#{last_name[0].upcase}." }].compact.join(' ')
    end

    private

    def email_address_not_anonymized
      return unless email_address&.end_with?(ANONYMIZED_EMAIL_DOMAIN)

      errors.add(:email_address, 'não está disponível')
    end
  end
end
