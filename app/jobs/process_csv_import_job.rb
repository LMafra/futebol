require 'csv'

class ProcessCsvImportJob < ApplicationJob
  class InvalidRow < StandardError; end

  queue_as :default

  BATCH_SIZE = 500
  UPSERT_COLUMNS = %i[championship_id home_team_id away_team_id match_date home_score away_score updated_at].freeze

  def perform(csv_import_id)
    task = Core::CsvImport.find(csv_import_id)
    task.update!(status: 'processing', rows_processed: 0)
    task.csv_file.open { |file| import_rows(task, file) }
    task.update!(status: 'completed')
  rescue StandardError => e
    report_failure(e, csv_import_id:)
    task&.fail!(e)
  end

  private

  # Streams the tempfile row by row; the CSV is never loaded whole into memory.
  def import_rows(task, file)
    CSV.foreach(file.path, headers: true, encoding: 'bom|utf-8').each_slice(BATCH_SIZE) do |batch|
      Core::Match.import(rows_for(batch), validate: false,
                                          on_duplicate_key_update: { conflict_target: [:external_id],
                                                                     columns: UPSERT_COLUMNS })
      task.increment!(:rows_processed, batch.size)
    end
  end

  def rows_for(batch)
    teams = ids_by_external_id(Core::Team, batch.flat_map { |row| row.values_at('home_team', 'away_team') })
    championships = ids_by_external_id(Core::Championship, batch.map { |row| row['championship'] })

    batch.map { |row| match_attributes(row, teams:, championships:) }
  end

  def match_attributes(row, teams:, championships:)
    {
      external_id: required(row, 'external_id'),
      championship_id: lookup(championships, row, 'championship'),
      home_team_id: lookup(teams, row, 'home_team'),
      away_team_id: lookup(teams, row, 'away_team'),
      match_date: Time.zone.parse(required(row, 'match_date')),
      home_score: score(row['home_score']),
      away_score: score(row['away_score'])
    }
  end

  def ids_by_external_id(model, external_ids)
    model.where(external_id: external_ids.compact.uniq).pluck(:external_id, :id).to_h
  end

  def required(row, column)
    row[column].presence || raise(InvalidRow, "partida #{row['external_id'].inspect}: coluna '#{column}' vazia")
  end

  def lookup(ids, row, column)
    external_id = required(row, column)
    ids.fetch(external_id) do
      raise InvalidRow, "partida #{row['external_id'].inspect}: #{column} '#{external_id}' não encontrado"
    end
  end

  def score(value) = value.presence && Integer(value, 10)

  def report_failure(error, csv_import_id:)
    Rails.logger.error("ProcessCsvImportJob failed csv_import_id=#{csv_import_id}: #{error.class} #{error.message}")
    Sentry.capture_exception(error, extra: { csv_import_id: })
  end
end
