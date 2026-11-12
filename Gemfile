source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.4'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem 'tailwindcss-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 2.2'

# Domain and platform gems (docs/spec-v2.md §1; activeadmin per docs/adr/0002-activeadmin-rails81.md Plan A)
gem 'aasm', '~> 6.0'
gem 'activeadmin', '4.0.0.beta23'
gem 'activerecord-import', '~> 3.0'
gem 'aws-sdk-s3', '~> 1.238', require: false
gem 'discard', '~> 2.0'
gem 'faraday', '~> 2.15'
gem 'lograge', '~> 0.15'
gem 'mission_control-jobs', '~> 1.3'
gem 'pundit', '~> 2.5'
gem 'rails-i18n', '~> 8.0'
gem 'stoplight', '~> 6.0'
# Blocks unsafe migrations (locks, rewrites); in every group because migrations call safety_assured and the
# deploy runs them (db:prepare) [https://github.com/ankane/strong_migrations]
gem 'strong_migrations', '~> 2.8'
gem 'view_component', '~> 4.20'

gem 'bolao', path: 'engines/bolao'
gem 'cartola', path: 'engines/cartola'
gem 'core', path: 'engines/core'
gem 'simulador', path: 'engines/simulador'

# Observability: traces (stable) and log records (logs SDK is still 0.x) over OTLP/HTTP to OpenObserve
# (config/initializers/opentelemetry.rb).
gem 'opentelemetry-exporter-otlp', '~> 0.37'
gem 'opentelemetry-exporter-otlp-logs', '~> 0.7'
gem 'opentelemetry-instrumentation-all', '~> 0.99'
gem 'opentelemetry-instrumentation-logger', '~> 0.5'
gem 'opentelemetry-logs-sdk', '~> 0.8'
gem 'opentelemetry-sdk', '~> 1.13'

group :development, :test do
  gem 'factory_bot_rails', '~> 6.5'
  gem 'rspec-rails', '~> 8.0'

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem 'bundler-audit', require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop-rails-omakase', require: false

  # Schema × model mismatches (missing NOT NULL, unique index, FK) [https://github.com/djezzzl/database_consistency]
  gem 'database_consistency', '~> 3.1', require: false
  # N+1 detection; specs fail on a detected N+1 (spec/support/prosopite.rb). pg_query fingerprints Postgres SQL.
  gem 'pg_query', '~> 6.2'
  gem 'prosopite', '~> 2.5'
end

group :test do
  # System specs (spec/system) in headless Chrome over CDP, no chromedriver [https://github.com/rubycdp/cuprite]
  gem 'capybara', '~> 3.40'
  gem 'cuprite', '~> 0.20'
end

group :development do
  gem 'letter_opener', '~> 1.10'
  gem 'lookbook', '~> 2.3'
  gem 'packwerk', '~> 3.3'

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end
