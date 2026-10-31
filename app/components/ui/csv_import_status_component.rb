module Ui
  class CsvImportStatusComponent < BaseComponent
    STATUS_LABELS = {
      'pending' => 'Na fila', 'processing' => 'Processando', 'completed' => 'Concluída', 'failed' => 'Falhou'
    }.freeze

    attr_reader :csv_import

    def initialize(csv_import: nil, state: :default)
      super(state:)
      @csv_import = csv_import
      require_in_default_state!(:csv_import, csv_import)
    end

    private

    def status_label = STATUS_LABELS.fetch(csv_import.status, csv_import.status)

    def rows_processed = csv_import&.rows_processed || 0

    def rows_label = "#{rows_processed} #{rows_processed == 1 ? 'linha processada' : 'linhas processadas'}"
  end
end
