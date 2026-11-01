# Without SENTRY_DSN, development reports to log/sentry_debug_events.log through a local stub DSN;
# test and production send nothing until a real DSN is set.
sentry_dsn = ENV['SENTRY_DSN'].presence

Sentry.init do |config|
  config.dsn = sentry_dsn
  config.environment = ENV['SENTRY_ENVIRONMENT'].presence || Rails.env
  config.enabled_environments = %w[production development]
  config.release = ENV['RENDER_GIT_COMMIT'].presence
  config.send_default_pii = false
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = Float(ENV['SENTRY_TRACES_SAMPLE_RATE'].presence || (Rails.env.production? ? '0.05' : '0'))

  if Rails.env.development? && sentry_dsn.nil?
    config.dsn = 'http://stub@localhost/0'
    config.transport.transport_class = Sentry::DebugTransport
  end
end
