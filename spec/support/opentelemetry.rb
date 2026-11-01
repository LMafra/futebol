# The test env exports nothing (config/initializers/opentelemetry.rb); specs read finished spans and log records
# from memory instead.
OTEL_SPANS = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
OTEL_LOG_RECORDS = OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter.new
OpenTelemetry.tracer_provider.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(OTEL_SPANS))
OpenTelemetry.logger_provider.add_log_record_processor(
  OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(OTEL_LOG_RECORDS)
)

module OpenTelemetryHelpers
  def finished_spans = OTEL_SPANS.finished_spans

  def error_spans(type = nil)
    finished_spans.select do |span|
      span.status.code == OpenTelemetry::Trace::Status::ERROR && span.name.start_with?('exception ') &&
        (type.nil? || span.attributes['exception.type'] == type.to_s)
    end
  end
end

RSpec.configure do |config|
  config.include OpenTelemetryHelpers
  config.before do
    OTEL_SPANS.reset
    OTEL_LOG_RECORDS.reset
  end
end
