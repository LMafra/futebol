module Core
  class User < ApplicationRecord
    has_secure_password
    has_many :sessions, class_name: 'Core::Session', dependent: :destroy

    normalizes :email_address, with: ->(email) { email.strip.downcase }
    normalizes :cpf, with: ->(cpf) { cpf.gsub(/\D/, '').presence }

    scope :active, -> { where(active: true) }

    validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 8 }, allow_nil: true
    validates :cpf, format: { with: /\A\d{11}\z/ }, uniqueness: true, allow_nil: true

    def to_s = email_address
  end
end
