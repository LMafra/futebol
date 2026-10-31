module Core
  class CsvImport < ApplicationRecord
    STATUSES = %w[pending processing completed failed].freeze

    has_one_attached :csv_file

    validates :status, inclusion: { in: STATUSES }
    validates :rows_processed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :error_message, :error_log, presence: true, if: -> { status == 'failed' }

    def fail!(error)
      update!(status: 'failed', error_message: error.message.presence || error.class.name,
              error_log: [error.class.name, error.message, *Array(error.backtrace).first(10)].join("\n"))
    end
  end
end
