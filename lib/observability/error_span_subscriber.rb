module Observability
  # Rails.error subscriber (config/initializers/opentelemetry.rb): every reported exception — explicit
  # Rails.error.report calls and the unhandled request/job errors Rails reports itself — becomes an OTel span with
  # error status, a child of the current request/job span when there is one.
  class ErrorSpanSubscriber
    BACKTRACE_LINES = 50
    CONTEXT_TYPES = [String, Symbol, Integer, Float, TrueClass, FalseClass].freeze

    def report(error, handled:, severity:, context:, source: nil)
      attributes = exception_attributes(error).merge(
        'exception.handled' => handled, 'exception.severity' => severity.to_s, 'exception.source' => source.to_s,
        **context_attributes(context)
      )

      tracer.in_span("exception #{error.class.name}", attributes:) do |span|
        span.record_exception(error)
        span.status = OpenTelemetry::Trace::Status.error(error.message)
      end
    end

    private

    def exception_attributes(error)
      {
        'exception.type' => error.class.name,
        'exception.message' => String.new(error.message.to_s),
        'exception.backtrace' => Array(error.backtrace).first(BACKTRACE_LINES).join("\n")
      }
    end

    # Only scalar context (ids, tokens) is exported; request/job objects Rails adds to the context are skipped.
    # OTel accepts plain String instances only, so String subclasses and symbols are converted.
    def context_attributes(context)
      context.to_h.each_with_object({}) do |(key, value), attributes|
        next unless CONTEXT_TYPES.any? { |type| value.is_a?(type) }

        attributes["error.context.#{key}"] = value.is_a?(String) || value.is_a?(Symbol) ? String.new(value.to_s) : value
      end
    end

    def tracer = OpenTelemetry.tracer_provider.tracer('futebol.errors')
  end
end
