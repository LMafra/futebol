# TICKET-0009 — (i) ProcessCsvImportJob (streaming + rescue + upsert external_id)

- Deps: TICKET-0002
- Skill: [W]tdd
- MCP: [r2] bucket `futebol-dev` para ActiveStorage em dev (opcional; fallback disk)
- Spec: §8

## Paths
- `app/jobs/process_csv_import_job.rb`, `engines/core/app/models/core/csv_import.rb`
- `spec/jobs/process_csv_import_job_spec.rb`, `spec/fixtures/files/matches.csv`

## Pronto quando
- `csv_file.open` + `CSV.foreach` em lotes de 500 (nunca `CSV.read`)
- `Core::Match.import(..., on_duplicate_key_update: { conflict_target: [:external_id] })`
- `rescue` → `status: 'failed'`, `error_message`

## Teste antes/depois
- Antes: reimportar CSV duplica partidas; CSV malformado deixa status `processing`
- Depois: importar 2× → mesma contagem e placar atualizado; CSV malformado → `failed` + mensagem; spec garante `expect(CSV).not_to receive(:read)`
