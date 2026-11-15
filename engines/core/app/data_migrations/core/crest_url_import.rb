require 'net/http'

module Core
  # Best effort: downloads each team's crest_url into the crest attachment before the column goes (ADR 0006).
  # A URL that fails (timeout, not an image, too big) is logged and skipped; the team falls back to its short name.
  class CrestUrlImport
    TIMEOUT = 5

    def initialize(connection = ActiveRecord::Base.connection, logger: Rails.logger)
      @connection = connection
      @logger = logger
    end

    def run
      connection.select_rows("SELECT id, crest_url FROM core_teams WHERE crest_url <> ''").each do |id, url|
        import(id, url)
      end
    end

    private

    attr_reader :connection, :logger

    def import(team_id, url)
      uri = URI.parse(url)
      response = checked(fetch(uri))
      attach(team_id, response.body, File.basename(uri.path).presence || "escudo-#{team_id}", response.content_type)
    rescue StandardError => e
      logger.warn("crest_url do time #{team_id} não importado (#{url}): #{e.message}")
    end

    def checked(response)
      unless response.is_a?(Net::HTTPSuccess) && ImageAttachment::CONTENT_TYPES.include?(response.content_type)
        raise "resposta #{response.code} #{response.content_type}"
      end
      raise 'maior que 2 MB' if response.body.bytesize > ImageAttachment::MAX_SIZE

      response
    end

    def fetch(uri)
      raise ArgumentError, 'só http e https' unless uri.is_a?(URI::HTTP)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: TIMEOUT,
                                          read_timeout: TIMEOUT) { |http| http.get(uri.request_uri) }
    end

    def attach(team_id, body, filename, content_type)
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(body), filename:, content_type:)
      ActiveStorage::Attachment.create!(name: 'crest', record_type: 'Core::Team', record_id: team_id, blob:)
    end
  end
end
