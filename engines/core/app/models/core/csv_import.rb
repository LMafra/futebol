module Core
  class CsvImport < ApplicationRecord
    STATUSES = %w[pending processing completed failed].freeze

    validates :status, inclusion: { in: STATUSES }
    validates :rows_processed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
