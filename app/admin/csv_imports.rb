ActiveAdmin.register Core::CsvImport, as: 'CsvImport' do
  menu parent: 'Cadastros', label: 'Importações CSV'

  actions :index, :show, :new, :create
  permit_params :csv_file
  config.sort_order = 'created_at_desc'

  filter :status, as: :select, collection: -> { Core::CsvImport::STATUSES }
  filter :created_at

  index do
    id_column
    column(:status) { |csv_import| status_tag csv_import.status }
    column :rows_processed
    column :error_message
    column :created_at
    actions
  end

  show do
    attributes_table do
      row(:status) { |csv_import| status_tag csv_import.status }
      row(:csv_file) { |csv_import| csv_import.csv_file.filename if csv_import.csv_file.attached? }
      row :rows_processed
      row :error_message
      row(:error_log) { |csv_import| pre csv_import.error_log if csv_import.error_log }
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs 'Arquivo CSV (external_id, championship, home_team, away_team, match_date, home_score, away_score)' do
      f.input :csv_file, as: :file, input_html: { accept: '.csv,text/csv' }
    end
    f.actions
  end

  controller do
    def create
      csv_import = build_resource
      authorize! :import, csv_import

      if csv_import.save(context: :upload)
        ProcessCsvImportJob.perform_later(csv_import.id)
        redirect_to admin_csv_import_path(csv_import), notice: 'Importação enfileirada.'
      else
        render :new, status: :unprocessable_content
      end
    end
  end
end
