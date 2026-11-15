require 'rails_helper'

RSpec.describe Core::CrestUrlImport do
  let(:logger) { instance_double(Logger, warn: nil) }
  let(:team) { create(:team) }

  def response(klass, body:, content_type:)
    klass.new('1.1', klass == Net::HTTPOK ? '200' : '404', '').tap do |http_response|
      http_response.content_type = content_type
      allow(http_response).to receive(:body).and_return(body)
    end
  end

  # crest_url is gone from the schema; the import runs against rows read by SQL, stubbed here.
  def run_with(rows)
    connection = ActiveRecord::Base.connection
    allow(connection).to receive(:select_rows).and_call_original
    allow(connection).to receive(:select_rows).with(/crest_url/).and_return(rows)
    described_class.new(connection, logger:).run
  end

  it 'attaches the downloaded image as the crest' do
    allow(Net::HTTP).to receive(:start)
      .and_return(response(Net::HTTPOK, body: file_fixture('crest.png').binread, content_type: 'image/png'))

    run_with([[team.id, 'https://example.com/escudos/fla.png']])

    expect(team.reload.crest).to be_attached
    expect(team.crest.filename.to_s).to eq('fla.png')
  end

  it 'skips and logs URLs that fail or are not images' do
    allow(Net::HTTP).to receive(:start).and_return(response(Net::HTTPNotFound, body: '', content_type: 'text/html'))

    run_with([[team.id, 'https://example.com/sumiu.png'], [team.id, 'ftp://example.com/escudo.png']])

    expect(team.reload.crest).not_to be_attached
    expect(logger).to have_received(:warn).twice
  end
end
