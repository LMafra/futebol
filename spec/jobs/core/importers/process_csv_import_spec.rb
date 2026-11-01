require 'rails_helper'

RSpec.describe ProcessCsvImportJob do
  let(:header) { "external_id,championship,home_team,away_team,match_date,home_score,away_score\n" }

  before do
    create(:championship, external_id: 'brasileirao-2026')
    %w[flamengo palmeiras corinthians santos].each { |external_id| create(:team, external_id:) }
  end

  def csv_import_with(content = nil, fixture: nil)
    create(:csv_import).tap do |task|
      io = fixture ? file_fixture(fixture).open : StringIO.new(content)
      task.csv_file.attach(io:, filename: 'matches.csv', content_type: 'text/csv')
    end
  end

  def perform(task)
    described_class.perform_now(task.id)
    task.reload
  end

  describe 'upload válido' do
    let(:task) { csv_import_with(fixture: 'matches.csv') }

    it 'importa as partidas e termina com status completed' do
      expect { perform(task) }.to change(Core::Match, :count).by(3)

      expect(task).to have_attributes(status: 'completed', rows_processed: 3, error_message: nil, error_log: nil)
      expect(Core::Match.find_by!(external_id: 'br26-r01-flaxpal'))
        .to have_attributes(home_team: Core::Team.find_by!(external_id: 'flamengo'), home_score: 2, away_score: 1,
                            status: 'scheduled', match_date: Time.zone.parse('2026-04-12 16:00'))
      expect(Core::Match.find_by!(external_id: 'br26-r02-palxcor')).to have_attributes(home_score: nil, away_score: nil)
    end

    it 'lê em streaming via task.csv_file.open: nunca CSV.read nem download inteiro do blob' do
      blob = task.csv_file.blob
      allow(Core::CsvImport).to receive(:find).with(task.id).and_return(task)
      allow(blob).to receive(:open).and_call_original
      allow(blob).to receive(:download).and_call_original
      allow(CSV).to receive(:read).and_call_original

      expect(perform(task)).to have_attributes(status: 'completed')

      expect(blob).to have_received(:open)
      expect(blob).not_to have_received(:download)
      expect(CSV).not_to have_received(:read)
    end

    it 'importa em lotes de até 500 linhas' do
      rows = Array.new(501) { |i| "big-#{i},brasileirao-2026,flamengo,santos,2026-05-01 16:00,1,0\n" }
      big = csv_import_with(header + rows.join)
      allow(Core::Match).to receive(:import).and_call_original

      expect(perform(big)).to have_attributes(status: 'completed', rows_processed: 501)
      expect(Core::Match).to have_received(:import).twice
    end
  end

  describe 'external_id duplicado' do
    let!(:existing) do
      create(:match, external_id: 'br26-r01-flaxpal', home_score: nil, away_score: nil,
                     home_team: Core::Team.find_by!(external_id: 'flamengo'),
                     away_team: Core::Team.find_by!(external_id: 'palmeiras'))
    end

    it 'faz upsert via on_duplicate_key_update em external_id: atualiza o placar sem duplicar' do
      allow(Core::Match).to receive(:import).and_call_original

      expect { perform(csv_import_with(fixture: 'matches.csv')) }.to change(Core::Match, :count).by(2)

      expect(existing.reload).to have_attributes(home_score: 2, away_score: 1)
      expect(Core::Match).to have_received(:import)
        .with(anything, hash_including(on_duplicate_key_update: hash_including(conflict_target: [:external_id])))
    end

    it 'reimportar o mesmo CSV mantém a contagem' do
      perform(csv_import_with(fixture: 'matches.csv'))

      expect { perform(csv_import_with(fixture: 'matches.csv')) }.not_to change(Core::Match, :count)
    end
  end

  describe 'coluna round (opcional)' do
    let(:round_header) { "external_id,championship,home_team,away_team,match_date,home_score,away_score,round\n" }
    let(:row) { 'br26-r05-x,brasileirao-2026,flamengo,palmeiras,2026-05-03 16:00,,' }

    it 'grava a rodada quando a coluna existe' do
      perform(csv_import_with("#{round_header}#{row},5\n"))

      expect(Core::Match.find_by!(external_id: 'br26-r05-x').round).to eq(5)
    end

    it 'mantém a rodada já gravada ao reimportar sem a coluna' do
      perform(csv_import_with("#{round_header}#{row},5\n"))
      perform(csv_import_with("#{header}#{row}\n"))

      expect(Core::Match.find_by!(external_id: 'br26-r05-x').round).to eq(5)
    end

    it 'rodada fora de 1..38 → failed com mensagem apontando a partida' do
      task = perform(csv_import_with("#{round_header}#{row},39\n"))

      expect(task).to have_attributes(status: 'failed')
      expect(task.error_message).to eq(%(partida "br26-r05-x": rodada '39' fora de 1..38))
    end
  end

  describe 'arquivo vazio' do
    it 'termina completed com 0 rows (arquivo sem bytes)' do
      expect { @task = perform(csv_import_with('')) }.not_to change(Core::Match, :count)
      expect(@task).to have_attributes(status: 'completed', rows_processed: 0)
    end

    it 'termina completed com 0 rows (só cabeçalho)' do
      expect(perform(csv_import_with(header))).to have_attributes(status: 'completed', rows_processed: 0)
    end
  end

  describe 'falhas (rescue)' do
    it 'erro de encoding → status failed com error_log' do
      task = perform(csv_import_with("#{header}br26-x,brasileirao-2026,flamengo,santos,2026-05-01 16:00,\xFF,0\n".b))

      expect(task).to have_attributes(status: 'failed', rows_processed: 0)
      expect(task.error_message).to match(/invalid byte sequence/i)
      expect(task.error_log).to start_with('CSV::InvalidEncodingError')
      expect(Core::Match.where(external_id: 'br26-x')).to be_empty
    end

    [Net::ReadTimeout, ActiveStorage::FileNotFoundError].each do |r2_error|
      it "falha de R2 (#{r2_error}) → status failed com error_log" do
        task = csv_import_with(fixture: 'matches.csv')
        allow(task.csv_file.blob.service).to receive(:download).and_raise(r2_error)

        expect { perform(task) }.not_to change(Core::Match, :count)

        expect(task).to have_attributes(status: 'failed')
        expect(task.error_message).to be_present
        expect(task.error_log).to start_with(r2_error.name)
      end
    end

    it 'time desconhecido → failed com mensagem apontando a partida' do
      task = perform(csv_import_with("#{header}br26-y,brasileirao-2026,gremio,santos,2026-05-01 16:00,1,0\n"))

      expect(task).to have_attributes(status: 'failed')
      expect(task.error_message).to eq(%(partida "br26-y": home_team 'gremio' não encontrado))
    end

    it 'registra o erro no log e num span OTel de erro, sem re-raise (arquivo inválido não melhora com retry)' do
      allow(Rails.logger).to receive(:error).and_call_original
      task = csv_import_with("#{header}br26-z,brasileirao-2026,flamengo,santos,2026-05-01 16:00,abc,0\n")

      expect { perform(task) }.not_to raise_error

      expect(Rails.logger).to have_received(:error)
        .with(/ProcessCsvImportJob failed csv_import_id=#{task.id}: ArgumentError/)
      expect(error_spans(ArgumentError).sole.attributes)
        .to include('error.context.csv_import_id' => task.id, 'exception.severity' => 'error')
    end
  end
end
