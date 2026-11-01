namespace :observability do
  desc 'Report a fake exception through Rails.error and flush the error span to OpenObserve'
  task fake_exception: :environment do
    OpenTelemetry.tracer_provider.tracer('futebol.tasks').in_span('observability:fake_exception') do |span|
      raise 'Observability fake exception (bin/rails observability:fake_exception)'
    rescue RuntimeError => e
      Rails.error.report(e, context: { task: 'observability:fake_exception' })
      puts "Error span reported in trace #{span.context.hex_trace_id}"
    end
    OpenTelemetry.tracer_provider.force_flush
  end
end
