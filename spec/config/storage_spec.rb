require 'rails_helper'
require 'aws-sdk-s3'

RSpec.describe 'config/storage.yml' do
  def r2_config(env)
    stub_const('ENV', ENV.to_h.except('R2_ENDPOINT').merge('AWS_EC2_METADATA_DISABLED' => 'true', **env))
    ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/storage.yml'))
  end

  def r2_service(env) = ActiveStorage::Service.configure(:r2, r2_config(env).deep_symbolize_keys)

  it 'points the r2 service at the Cloudflare R2 endpoint of the account' do
    service = r2_service('R2_ACCOUNT_ID' => 'abc123', 'R2_ACCESS_KEY_ID' => 'key', 'R2_SECRET_ACCESS_KEY' => 'secret')
    client = service.client.client.config

    expect(service).to be_a(ActiveStorage::Service::S3Service)
    expect(client.endpoint.to_s).to eq('https://abc123.r2.cloudflarestorage.com')
    expect(client).to have_attributes(region: 'auto', access_key_id: 'key',
                                      request_checksum_calculation: 'when_required')
  end

  it 'uses R2_ENDPOINT when set and the dev bucket outside production' do
    service = r2_service('R2_ENDPOINT' => 'https://custom.r2.cloudflarestorage.com', 'R2_BUCKET_DEV' => 'futebol-dev',
                         'R2_ACCESS_KEY_ID' => 'key', 'R2_SECRET_ACCESS_KEY' => 'secret')

    expect(service.client.client.config.endpoint.to_s).to eq('https://custom.r2.cloudflarestorage.com')
    expect(service.bucket.name).to eq('futebol-dev')
  end
end
