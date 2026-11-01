namespace :sentry do
  desc 'Raise and capture a fake exception to check the Sentry setup'
  task fake_exception: :environment do
    raise 'Sentry fake exception (bin/rails sentry:fake_exception)'
  rescue RuntimeError => e
    event = Sentry.capture_exception(e, tags: { source: 'sentry:fake_exception' })
    abort 'Sentry did not capture the event: set SENTRY_DSN (or run in development for the stub)' unless event

    Sentry.get_current_client.flush
    destination = Sentry.configuration.dsn.local? ? Sentry::DebugTransport::DEFAULT_LOG_FILE_PATH : 'Sentry'
    puts "Sentry event #{event.event_id} sent to #{destination} (environment: #{Sentry.configuration.environment})"
  end
end
