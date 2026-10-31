module Ui
  # @label CSV import status
  class CsvImportStatusComponentPreview < ViewComponent::Preview
    def default
      render CsvImportStatusComponent.new(csv_import: Core::CsvImport.new(status: 'completed', rows_processed: 380))
    end

    def loading
      render CsvImportStatusComponent.new(
        csv_import: Core::CsvImport.new(status: 'processing', rows_processed: 120), state: :loading
      )
    end

    def empty
      render CsvImportStatusComponent.new(state: :empty)
    end

    def error
      render CsvImportStatusComponent.new(
        csv_import: Core::CsvImport.new(status: 'failed', error_message: 'Linha 42: time "XYZ" não encontrado.'),
        state: :error
      )
    end
  end
end
