require 'rails_helper'
require 'rake'
require 'sentry/test_helper'

RSpec.describe 'Sentry' do
  include Sentry::TestHelper

  before { setup_sentry_test }
  after { teardown_sentry_test }

  describe 'configuration (config/initializers/sentry.rb)' do
    it 'reads the DSN from ENV, filters PII and keeps tracing low' do
      config = Sentry.configuration

      expect(config.send_default_pii).to be(false)
      expect(config.enabled_environments).to include('production', 'development')
      expect(config.traces_sample_rate).to be <= 0.1
      expect(File.read(Rails.root.join('config/initializers/sentry.rb'))).to include("ENV['SENTRY_DSN'].presence")
    end
  end

  describe 'jobs with rescue' do
    it 'ProcessMatchPointsJob reports the exception and re-raises' do
      match = create(:match, status: 'finished', home_score: 2, away_score: 1, match_date: 1.day.ago)
      allow(Scoring::Engine).to receive(:points_for).and_raise(RuntimeError, 'engine exploded')
      create(:bolao_prediction, match:)

      expect { ProcessMatchPointsJob.perform_now(match.id, 'token-1') }.to raise_error(RuntimeError)

      event = last_sentry_event
      expect(event.exception.values.last).to have_attributes(type: 'RuntimeError', value: include('engine exploded'))
      expect(event.extra).to include(match_id: match.id, scoring_token: 'token-1')
    end

    it 'ProcessCsvImportJob reports the exception and fails the import' do
      csv_import = create(:csv_import)
      csv_import.csv_file.attach(io: StringIO.new("external_id\nx\n"), filename: 'broken.csv')

      ProcessCsvImportJob.perform_now(csv_import.id)

      expect(csv_import.reload.status).to eq('failed')
      expect(last_sentry_event.extra).to include(csv_import_id: csv_import.id)
    end
  end

  describe 'bin/rails sentry:fake_exception' do
    before { Rails.application.load_tasks unless Rake::Task.task_defined?('sentry:fake_exception') }

    it 'captures the fake exception' do
      expect { Rake::Task['sentry:fake_exception'].execute }.to output(/Sentry event \h{32} sent/).to_stdout

      expect(last_sentry_event.exception.values.last.value).to include('Sentry fake exception')
      expect(last_sentry_event.tags).to include(source: 'sentry:fake_exception')
    end
  end
end
