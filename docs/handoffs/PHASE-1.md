# Handoff — Fase 1 (ADR) — warning (acceptance 5/5)

## Decisões (ver `docs/adr/0001-arch.md`)
- Monolito modular: `app/` + `engines/{core,bolao,cartola,simulador}`; engines → core apenas (packwerk)
- Match AASM: scheduled → live → finished → scored; `revert_match!` scored → finished
- Guard: `revert_match!` checa `scores_calculated_at.present?` → RevertMatchPointsService → só então zera `scores_calculated_at`/`scoring_token` e grava `reversal_token`
- Colunas: status, scores_calculated_at, scoring_token(uuid), reversal_token(uuid), discarded_at
- Jobs: ProcessMatchPointsJob(match_id, scoring_token), RevertMatchPointsJob(match_id, reversal_token), ProcessCsvImportJob(csv_import_id), BroadcastUpdateService.call(match) com `unless_exist`
- Pundit por action; 5 policies: Match, CsvImport, Pool, Squad, AuditLog
- `scoring_token` ≠ scoring_version; `match_date` ≠ kickoff_at
- 7 correções listadas no fim do ADR (check constraint, csv_file.open, candidate_home/away, unless_exist, seeds sem array, AuditLog ip_address)

## Paths
- `docs/adr/0001-arch.md`, `GLOSSARY.md`

## Avisos
- Docs de arquitetura originais ausentes → contratos inferidos do prompt
