require 'rails_helper'
require 'open3'

# foreman (bin/dev) loads .env, so every blank KEY= from .env.example reaches ENV as an empty string.
RSpec.describe '.env.example' do
  let(:script) do
    <<~RUBY
      config = Rails.application.config
      puts JSON.dump(
        storage: config.active_storage.service,
        otel_service: OpenTelemetry.tracer_provider.resource.attribute_enumerator.to_h['service.name'],
        otel_traces_uri: OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
                                      .filter_map { |p| p.instance_variable_get(:@exporter)&.instance_variable_get(:@uri)&.to_s }.first,
        otel_traces_auth: OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
                                       .filter_map { |p| p.instance_variable_get(:@exporter)&.instance_variable_get(:@headers)&.fetch('authorization', nil) }.first,
        queue_url: ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue').try(:url),
        primary: ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'primary')
                                   .configuration_hash.slice(:prepared_statements, :advisory_locks, :sslmode)
      )
    RUBY
  end

  let(:example_env) do
    Rails.root.join('.env.example').readlines(chomp: true)
         .filter_map { |line| line.match(/\A([A-Z0-9_]+)=(.*)\z/)&.captures }
         .to_h.except('DB_HOST', 'DB_PORT', 'DB_USERNAME', 'DB_PASSWORD')
  end

  def boot(rails_env, extra = {})
    env = example_env.merge('RAILS_ENV' => rails_env, 'DATABASE_URL' => nil).merge(extra)
    output, status = Open3.capture2e(env, 'bin/rails', 'runner', script, chdir: Rails.root.to_s)
    raise "#{rails_env} boot failed with .env.example values: #{output}" unless status.success?

    JSON.parse(output.lines.last, symbolize_names: true)
  end

  it 'leaves DATABASE_URL commented out' do
    expect(example_env).not_to include('DATABASE_URL')
  end

  it 'boots development with blank values falling back to defaults' do
    expect(boot('development')).to include(storage: 'local', otel_service: 'futebol',
                                           otel_traces_uri: 'http://localhost:5080/api/default/v1/traces')
  end

  describe 'production' do
    let(:production_env) do
      { 'SECRET_KEY_BASE_DUMMY' => '1', 'R2_ACCESS_KEY_ID' => 'key', 'R2_SECRET_ACCESS_KEY' => 'secret' }
    end
    let(:pooler) { 'postgres://postgres.ref:p@aws-0-sa-east-1.pooler.supabase.com' }

    it 'boots with blank values falling back to defaults, on the Supabase transaction pooler' do
      settings = boot('production', production_env.merge('SUPABASE_DATABASE_URL' => "#{pooler}:6543/postgres"))

      expect(settings).to include(storage: 'r2', otel_service: 'futebol', otel_traces_uri: nil,
                                  queue_url: "#{pooler}:6543/postgres_queue",
                                  primary: { prepared_statements: false, advisory_locks: false, sslmode: 'require' })
    end

    it 'exports to a self-hosted OpenObserve from the standard OTEL_EXPORTER_OTLP_* variables' do
      settings = boot('production', production_env.merge(
                                      'SUPABASE_DATABASE_URL' => "#{pooler}:6543/postgres",
                                      'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://oo.example.com/api/default/',
                                      'OTEL_EXPORTER_OTLP_HEADERS' => 'authorization=Basic%20dTpw,organization=default'
                                    ))

      expect(settings).to include(otel_traces_uri: 'https://oo.example.com/api/default/v1/traces',
                                  otel_traces_auth: 'Basic dTpw')
    end

    it 'keeps prepared statements on the session pooler (db:prepare) and accepts DATABASE_URL as fallback' do
      settings = boot('production', production_env.merge('DATABASE_URL' => "#{pooler}:5432/postgres"))

      expect(settings).to include(queue_url: "#{pooler}:5432/postgres_queue",
                                  primary: { prepared_statements: true, advisory_locks: true, sslmode: 'require' })
    end
  end
end
