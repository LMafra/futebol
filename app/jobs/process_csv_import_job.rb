class ProcessCsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv_import_id)
    # TODO: TICKET-0009
    raise NotImplementedError
  end
end
