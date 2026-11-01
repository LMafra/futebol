# Without SENTRY_DSN, development reports to log/sentry_debug_events.log through a local stub DSN;
# test and production send nothing until a real DSN is set.
sentry_dsn = ENV.fetch('SENTRY_DSN', nil).presence

Sentry.init do |config|
  config.dsn = sentry_dsn
  config.environment = ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
  config.enabled_environments = %w[production development]
  config.release = ENV.fetch('RENDER_GIT_COMMIT', nil)
  config.send_default_pii = false
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = Float(ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', Rails.env.production? ? '0.05' : '0'))

  if Rails.env.development? && sentry_dsn.nil?
    config.dsn = 'http://stub@localhost/0'
    config.transport.transport_class = Sentry::DebugTransport
  end
end
