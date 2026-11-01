require 'rails_helper'
require 'open3'

# Boots the production environment in a subprocess: config/environments/production.rb never loads in the suite.
RSpec.describe 'config/environments/production.rb' do
  let(:script) do
    <<~RUBY
      config = Rails.application.config
      up = ActionDispatch::Request.new(Rack::MockRequest.env_for('/up'))
      root = ActionDispatch::Request.new(Rack::MockRequest.env_for('/'))
      puts JSON.dump(
        storage: config.active_storage.service,
        delivery: config.action_mailer.delivery_method,
        smtp: config.action_mailer.smtp_settings,
        from: ApplicationMailer.default[:from],
        hosts: config.hosts.map(&:to_s),
        ssl_redirect_skips_up: config.ssl_options.dig(:redirect, :exclude).call(up),
        ssl_redirect_skips_root: config.ssl_options.dig(:redirect, :exclude).call(root),
        host_check_skips_up: config.host_authorization[:exclude].call(up),
        force_ssl: config.force_ssl,
        queue: [config.active_job.queue_adapter, config.solid_queue.connects_to]
      )
    RUBY
  end

  let(:settings) do
    env = { 'RAILS_ENV' => 'production', 'SECRET_KEY_BASE_DUMMY' => '1', 'RESEND_API_KEY' => 're_test',
            'RESEND_FROM' => 'bolao@futebol.app', 'APP_HOST' => 'futebol.onrender.com',
            'R2_ACCESS_KEY_ID' => 'key', 'R2_SECRET_ACCESS_KEY' => 'secret',
            'ACTIVE_STORAGE_SERVICE' => nil, 'DATABASE_URL' => nil }
    output, status = Open3.capture2(env, 'bin/rails', 'runner', script, chdir: Rails.root.to_s)
    raise "production boot failed: #{output}" unless status.success?

    JSON.parse(output.lines.last, symbolize_names: true)
  end

  it 'stores uploads on R2, mails through Resend and keeps /up reachable for the health check' do
    expect(settings).to include(
      storage: 'r2',
      delivery: 'smtp',
      smtp: include(address: 'smtp.resend.com', port: 465, user_name: 'resend', password: 're_test', tls: true),
      from: 'bolao@futebol.app',
      hosts: include('futebol.onrender.com'),
      force_ssl: true,
      ssl_redirect_skips_up: true,
      ssl_redirect_skips_root: false,
      host_check_skips_up: true,
      queue: ['solid_queue', { database: { writing: 'queue' } }]
    )
  end
end
