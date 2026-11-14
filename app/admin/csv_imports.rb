ActiveAdmin.register Core::CsvImport, as: 'CsvImport' do
  menu parent: 'Configurações', label: 'Importações CSV', priority: 4

  actions :index, :show, :new, :create
  permit_params :csv_file
  config.sort_order = 'created_at_desc'

  filter :status, as: :select, collection: -> { admin_csv_import_status_options }
  filter :created_at

  AdminCollectionIndex.register(self, 'admin/listings/csv_imports')

  show do
    div class: 'mb-6' do
      state = resource.status == 'failed' ? :error : :default
      render Ui::CsvImportStatusComponent.new(csv_import: resource, state:)
    end
    attributes_table do
      row(:csv_file) { |csv_import| csv_import.csv_file.filename if csv_import.csv_file.attached? }
      row :rows_processed
      row :error_message
      row(:error_log) { |csv_import| pre csv_import.error_log if csv_import.error_log }
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs 'Arquivo CSV' do
      f.input :csv_file, as: :file, input_html: { accept: '.csv,text/csv' },
                         hint: 'Colunas esperadas, nesta ordem: external_id, championship, home_team, away_team, ' \
                               'match_date, home_score, away_score.'
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
