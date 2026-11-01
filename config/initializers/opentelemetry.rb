# Traces and log records go to a self-hosted OpenObserve over OTLP/HTTP. OTEL_EXPORTER_OTLP_ENDPOINT is the OTLP
# base URL of an OpenObserve organization (http://host:5080/api/<org>); /v1/traces and /v1/logs are appended, as
# in the OTel spec. Development defaults to the local OpenObserve (docker/openobserve/docker-compose.yml);
# production exports only when the variable is set; test never exports (spec/support/opentelemetry.rb keeps spans
# in memory). OTEL_EXPORTER_OTLP_HEADERS uses the OTel "key=value,key=value" format (values URL-decoded), e.g.
# "authorization=Basic <base64 email:password>,organization=default".
otlp_endpoint = ENV['OTEL_EXPORTER_OTLP_ENDPOINT'].presence&.delete_suffix('/')
otlp_endpoint ||= 'http://localhost:5080/api/default' if Rails.env.development?
otlp_endpoint = nil if Rails.env.test?

# The exporter rejects a blank string, which is what foreman loads from an empty KEY= in .env.
otlp_headers = ENV['OTEL_EXPORTER_OTLP_HEADERS'].presence || {}

# Without explicit processors the SDK would build OTLP exporters from OTEL_* env (default localhost:4318).
unless otlp_endpoint
  ENV['OTEL_TRACES_EXPORTER'] ||= 'none'
  ENV['OTEL_LOGS_EXPORTER'] ||= 'none'
end

# The SDK's own diagnostics must not be bridged back into OTel logs (an exporter failure would feed itself).
otel_logger = ActiveSupport::Logger.new($stderr, level: :warn)

OpenTelemetry::SDK.configure do |c|
  c.logger = otel_logger
  c.service_name = 'futebol'
  ENV['RENDER_GIT_COMMIT'].presence&.then { |commit| c.service_version = commit }
  c.resource = OpenTelemetry::SDK::Resources::Resource.create('deployment.environment.name' => Rails.env.to_s)

  # Rails (Action Pack/View, Active Record, Active Job → Solid Queue), Rack, PG, Faraday, Net::HTTP and the
  # Logger bridge that turns every log line (Lograge JSON included) into an OTel log record tied to the trace.
  c.use_all('OpenTelemetry::Instrumentation::Rack' => { untraced_endpoints: ['/up'] })

  if otlp_endpoint
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: "#{otlp_endpoint}/v1/traces", headers: otlp_headers)
      )
    )
    c.add_log_record_processor(
      OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
        OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new(endpoint: "#{otlp_endpoint}/v1/logs",
                                                              headers: otlp_headers)
      )
    )
  end
end

otel_logger.skip_otel_emit = true if otel_logger.respond_to?(:skip_otel_emit=)

Rails.application.config.after_initialize do
  Rails.error.subscribe(Observability::ErrorSpanSubscriber.new)
end
