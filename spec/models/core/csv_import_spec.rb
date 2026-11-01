require 'rails_helper'

RSpec.describe Core::CsvImport do
  it 'starts as pending with zero rows processed' do
    csv_import = create(:csv_import)

    expect(csv_import.status).to eq('pending')
    expect(csv_import.rows_processed).to eq(0)
  end

  it 'only accepts known statuses' do
    expect(build(:csv_import, status: 'done')).not_to be_valid
  end

  describe 'failed status' do
    it 'requires error_message and error_log' do
      expect(build(:csv_import, status: 'failed')).not_to be_valid
    end

    it 'is enforced by the database' do
      csv_import = create(:csv_import)

      expect { csv_import.update_column(:status, 'failed') }
        .to raise_error(ActiveRecord::StatementInvalid, /csv_imports_failed_has_error/)
    end

    it '#fail! stores the message and a log with the error class and backtrace' do
      csv_import = create(:csv_import)
      error = RuntimeError.new('boom').tap { |e| e.set_backtrace(%w[a.rb:1 b.rb:2]) }

      csv_import.fail!(error)

      expect(csv_import.reload).to have_attributes(status: 'failed', error_message: 'boom',
                                                   error_log: "RuntimeError\nboom\na.rb:1\nb.rb:2")
    end
  end
end
