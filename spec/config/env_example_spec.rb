require 'rails_helper'
require 'open3'

# foreman (bin/dev) loads .env, so every blank KEY= from .env.example reaches ENV as an empty string.
RSpec.describe '.env.example' do
  let(:script) do
    <<~RUBY
      config = Rails.application.config
      puts JSON.dump(
        storage: config.active_storage.service,
        sentry_environment: Sentry.configuration.environment,
        sentry_traces: Sentry.configuration.traces_sample_rate,
        queue_url: ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue').try(:url)
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
    expect(boot('development')).to include(storage: 'local', sentry_environment: 'development', sentry_traces: 0.0)
  end

  it 'boots production with blank values falling back to defaults' do
    settings = boot('production', 'SECRET_KEY_BASE_DUMMY' => '1', 'R2_ACCESS_KEY_ID' => 'key',
                                  'R2_SECRET_ACCESS_KEY' => 'secret',
                                  'DATABASE_URL' => 'postgres://u:p@db.example.com/neondb')

    expect(settings).to include(storage: 'r2', sentry_environment: 'production', sentry_traces: 0.05,
                                queue_url: 'postgres://u:p@db.example.com/neondb_queue')
  end
end
