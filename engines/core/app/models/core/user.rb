module Core
  class User < ApplicationRecord
    # Users::AnonymizeService rewrites emails into this reserved TLD (RFC 2606); nobody signs up with one.
    ANONYMIZED_EMAIL_DOMAIN = '@invalid'.freeze
    # Shown in public rankings for users who did not opt in (LGPD).
    PUBLIC_FALLBACK_NAME = 'Participante'.freeze

    has_secure_password
    has_many :sessions, class_name: 'Core::Session', dependent: :destroy
    has_many :managed_championships, class_name: 'Core::Championship', foreign_key: :manager_id,
                                     inverse_of: :manager, dependent: :restrict_with_error
    has_many :managed_teams, class_name: 'Core::Team', foreign_key: :manager_id, inverse_of: :manager,
                             dependent: :restrict_with_error

    # prefix: :role — without it, role value :admin collides with the boolean column admin.
    enum :role, { user: 0, manager: 1, admin: 2 }, prefix: :role
    # prefix: :manager — without it, value :none collides with ActiveRecord::Base.none.
    enum :manager_status, { none: 0, pending: 1, approved: 2, rejected: 3 }, prefix: :manager

    normalizes :email_address, with: ->(email) { email.strip.downcase }
    normalizes :cpf, with: ->(cpf) { cpf.gsub(/\D/, '').presence }

    scope :active, -> { where(active: true) }
    scope :managers, -> { where(role: :manager) }

    validates :email_address, presence: { message: 'não pode ficar em branco' },
                              uniqueness: { message: 'já está em uso' },
                              format: { with: URI::MailTo::EMAIL_REGEXP, message: 'não é um e-mail válido' }
    validates :password, length: { minimum: 8, message: 'deve ter pelo menos 8 caracteres' }, allow_nil: true
    validates :cpf, format: { with: /\A\d{11}\z/ }, uniqueness: true, allow_nil: true
    # Only on create: accounts made before signup existed (e.g. the seeded admin) may have no name.
    validates :name, presence: { message: 'não pode ficar em branco' }, on: :create
    validate :email_address_not_anonymized, on: :create

    def self.ransackable_attributes(_auth_object = nil) = %w[name email_address role manager_status]

    def to_s = email_address

    def public_profile_consented? = public_profile_consented_at.present?

    # First name and last-name initial ("Lucas M."), only with consent.
    def public_display_name
      first_name, *other_names = name.to_s.split
      return PUBLIC_FALLBACK_NAME unless public_profile_consented? && first_name

      [first_name, other_names.last&.then { |last_name| "#{last_name[0].upcase}." }].compact.join(' ')
    end

    # The enum is the source of truth; the boolean stays during the migration.
    def admin? = role_admin? || self[:admin]

    def manager? = role_manager? && manager_approved?

    def can_manage?(championship) = admin? || (manager? && championship.manager_id == id)

    private

    def email_address_not_anonymized
      return unless email_address&.end_with?(ANONYMIZED_EMAIL_DOMAIN)

      errors.add(:email_address, 'não está disponível')
    end
  end
end
