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
end
