# One JSON line per request on stdout (Render logs). The OTel Logger bridge (config/initializers/opentelemetry.rb)
# also ships each line to OpenObserve as a log record carrying the request's trace_id/span_id.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.test?
  config.lograge.formatter = Lograge::Formatters::Json.new
  # A plain logger keeps the body pure JSON (TaggedLogging would prefix "[request_id] ").
  config.lograge.logger = ActiveSupport::Logger.new($stdout) if Rails.env.production?
  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id, user_id: Current.user&.id }
  end
  config.lograge.custom_options = lambda do |event|
    span_context = OpenTelemetry::Trace.current_span.context
    options = { time: Time.current.iso8601(3) }
    options[:exception] = event.payload[:exception]&.first if event.payload[:exception]
    next options unless span_context.valid?

    options.merge(trace_id: span_context.hex_trace_id, span_id: span_context.hex_span_id)
  end
end
