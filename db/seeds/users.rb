module Seeds
  # Password only applies on creation; re-running never resets it.
  def self.admin
    Core::User.find_or_create_by!(email_address: ENV.fetch('SEED_ADMIN_EMAIL', 'admin@futebol.dev')) do |user|
      user.name = 'Administrador'
      user.password = ENV.fetch('SEED_ADMIN_PASSWORD') { admin_password_fallback }
      user.admin = true
      user.role = :admin
    end
  end

  def self.admin_password_fallback
    return 'futebol-admin' if Rails.env.local?

    raise KeyError, 'SEED_ADMIN_PASSWORD is required outside development/test'
  end
end
