require 'rails_helper'

RSpec.describe 'Admin CSV imports', type: :request do
  let(:upload) { Rack::Test::UploadedFile.new(file_fixture('matches.csv'), 'text/csv') }

  it 'uploads the file, authorizes import? and enqueues ProcessCsvImportJob' do
    sign_in(create(:user, :admin))

    expect { post '/admin/csv_imports', params: { csv_import: { csv_file: upload } } }
      .to change(Core::CsvImport, :count).by(1)
      .and have_enqueued_job(ProcessCsvImportJob)

    csv_import = Core::CsvImport.last
    expect(csv_import.csv_file).to be_attached
    expect(response).to redirect_to("/admin/csv_imports/#{csv_import.id}")
  end

  it 'requires a file' do
    sign_in(create(:user, :admin))

    expect { post '/admin/csv_imports', params: { csv_import: { csv_file: '' } } }
      .not_to change(Core::CsvImport, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'answers 403 to non-admins' do
    sign_in(create(:user))

    expect { post '/admin/csv_imports', params: { csv_import: { csv_file: upload } } }
      .not_to change(Core::CsvImport, :count)
    expect(response).to have_http_status(:forbidden)
  end
end
