require 'rails_helper'

RSpec.describe Ui::CsvImportStatusComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::CsvImportStatusComponentPreview

  it 'requires a csv_import in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /csv_import is required/)
  end

  it 'renders progress for a completed import' do
    page = render_inline(described_class.new(csv_import: Core::CsvImport.new(status: 'completed', rows_processed: 380)))

    expect(page.at_css('[data-role="status"]').text).to eq('Concluída')
    expect(page.at_css('[data-role="rows"]').text).to eq('380 linhas processadas')
  end

  it 'renders the processing view while loading' do
    page = render_inline(described_class.new(csv_import: Core::CsvImport.new(rows_processed: 1), state: :loading))

    expect(page.at_css('[data-role="status"]').text).to eq('Processando…')
    expect(page.at_css('[data-role="rows"]').text).to eq('1 linha processada')
    expect(page.at_css('[data-role="skeleton"]')).to be_present
  end

  it 'shows the empty message' do
    expect(render_inline(described_class.new(state: :empty)).text).to include('Nenhuma importação')
  end

  it 'shows the import error_message' do
    csv_import = Core::CsvImport.new(status: 'failed', error_message: 'Linha 42 inválida')
    page = render_inline(described_class.new(csv_import:, state: :error))

    expect(page.at_css('[data-role="error-message"]').text).to eq('Linha 42 inválida')
  end
end
