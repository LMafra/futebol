require 'rails_helper'

RSpec.describe 'N+1 detection (spec/support/prosopite.rb)' do
  before { create_list(:player, 3) }

  let(:n_plus_one_job) do
    Class.new(ApplicationJob) do
      def self.name = 'NPlusOneProbeJob'
      def perform(preload) = (preload ? Core::Player.includes(:team) : Core::Player).find_each { |p| p.team.name }
    end
  end

  it 'fails a job that loads an association once per record' do
    expect { n_plus_one_job.perform_now(false) }.to raise_error(Prosopite::NPlusOneQueriesError, /core_teams/)
  end

  it 'passes the same job when the association is preloaded' do
    expect { n_plus_one_job.perform_now(true) }.not_to raise_error
  end

  it 'fails a request with an N+1, raising out of the middleware instead of rendering a 500' do
    app = Prosopite::Middleware::Rack.new(lambda { |_env|
      Core::Player.find_each { |player| player.team.name }
      [200, { 'content-type' => 'text/plain' }, ['ok']]
    })

    expect { app.call(Rack::MockRequest.env_for('/probe')) }.to raise_error(Prosopite::NPlusOneQueriesError)
  end

  it 'mounts the middleware outermost in the test app' do
    expect(Rails.application.middleware.first.klass).to eq(Prosopite::Middleware::Rack)
  end
end
