require 'rails_helper'
require 'rake'

RSpec.describe 'Observability (OpenTelemetry → OpenObserve)' do
  describe 'config/initializers/opentelemetry.rb' do
    it 'names the service futebol and tags the environment' do
      attributes = OpenTelemetry.tracer_provider.resource.attribute_enumerator.to_h

      expect(attributes).to include('service.name' => 'futebol', 'deployment.environment.name' => 'test')
    end

    it 'installs the Rails, Rack, PG, Faraday, Active Job and Logger instrumentations' do
      installed = %w[Rails Rack PG Faraday ActiveJob Logger].index_with do |name|
        OpenTelemetry::Instrumentation.registry.lookup("OpenTelemetry::Instrumentation::#{name}")&.installed?
      end

      expect(installed.values).to all(be(true)), installed.inspect
    end

    it 'reads the OpenObserve endpoint and auth from ENV' do
      source = Rails.root.join('config/initializers/opentelemetry.rb').read

      expect(source).to include("ENV['OTEL_EXPORTER_OTLP_ENDPOINT']", "ENV['OTEL_EXPORTER_OTLP_HEADERS']",
                                "c.service_name = 'futebol'")
    end
  end

  describe 'request traces', type: :request do
    it 'records a server span per request, skipping the /up health check' do
      get '/session/new'
      get '/up'

      server_spans = finished_spans.select { |span| span.kind == :server }
      expect(server_spans.map { |span| span.attributes['url.path'] || span.attributes['http.target'] })
        .to eq(['/session/new'])
    end
  end

  describe Observability::ErrorSpanSubscriber do
    let(:error) do
      raise ArgumentError, 'placar inválido'
    rescue ArgumentError => e
      e
    end

    it 'turns Rails.error.report into an error span with exception.* attributes and scalar context' do
      Rails.error.report(error, context: { match_id: 42, scoring_token: 'tok', request: Object.new })

      span = error_spans('ArgumentError').sole
      expect(span.status.description).to eq('placar inválido')
      expect(span.attributes).to include('exception.type' => 'ArgumentError', 'exception.message' => 'placar inválido',
                                         'exception.handled' => true, 'error.context.match_id' => 42,
                                         'error.context.scoring_token' => 'tok')
      expect(span.attributes['exception.backtrace']).to include('observability_spec.rb')
      expect(span.attributes.keys).not_to include('error.context.request')
      expect(span.events.map(&:name)).to eq(['exception'])
    end

    it 'nests the error span under the active span' do
      parent = OpenTelemetry.tracer_provider.tracer('spec').in_span('job') do |span|
        Rails.error.report(error)
        span
      end

      expect(error_spans.sole.parent_span_id).to eq(parent.context.span_id)
    end

    it 'reports each exception once' do
      2.times { Rails.error.report(error) }

      expect(error_spans.size).to eq(1)
    end
  end

  describe 'log records' do
    it 'bridges Rails.logger lines to OTel log records carrying the trace id' do
      span = OpenTelemetry.tracer_provider.tracer('spec').in_span('work') do |current|
        Rails.logger.info('linha de teste')
        current
      end

      record = OTEL_LOG_RECORDS.emitted_log_records.find { |log| log.body.to_s.include?('linha de teste') }
      expect(record).to have_attributes(severity_text: 'INFO', trace_id: span.context.trace_id)
    end

    it 'formats Lograge request lines as JSON with the trace id' do
      lograge = Rails.application.config.lograge
      event = ActiveSupport::Notifications::Event.new('process_action.action_controller', nil, nil, 1, {})

      options = OpenTelemetry.tracer_provider.tracer('spec').in_span('request') do |span|
        lograge.custom_options.call(event).merge(expected_trace: span.context.hex_trace_id)
      end

      expect(lograge.formatter).to be_a(Lograge::Formatters::Json)
      expect(options[:trace_id]).to eq(options[:expected_trace])
    end
  end

  describe 'bin/rails observability:fake_exception' do
    before { Rails.application.load_tasks unless Rake::Task.task_defined?('observability:fake_exception') }

    it 'reports an error span inside the task trace' do
      expect { Rake::Task['observability:fake_exception'].execute }
        .to output(/Error span reported in trace \h{32}/).to_stdout

      expect(error_spans('RuntimeError').sole.attributes)
        .to include('error.context.task' => 'observability:fake_exception')
    end
  end
end
