# Handoff — Fase 3 (Spec) — ok

## Decisões (`docs/spec.md`)
- §1 Gems fixadas (aasm 6.0, discard 2.0, ar-import 3.0, pundit 2.5, activeadmin 3.5, view_component 4.20, lookbook 2.3, stoplight 6.0, faraday 2.15, sentry 7.2, lograge 0.15, turbo-rails 2.0, packwerk 3.3, rspec-rails 8.0)
- §2 Migrations core/bolao/cartola com `add_check_constraint` (status, scored⇔timestamp, times distintos, placar ≥0)
- §3 `revert_match!`: guard → transition `after` (RevertMatchPointsService + assign nil) → save único
- §4 `config/tailwind.config.js` com tokens do design; win/draw/loss como tints
- §5 5 ViewComponents × 4 estados; previews Lookbook
- §6 ActiveAdmin: matches(revert/preview), csv_imports, pools, squads, audit_logs, Scoring Dashboard
- §7 Services: CalculatePreviewService(candidate_home/away), Scoring::Engine, Cartola preview Data.define, RevertMatchPointsService, BroadcastUpdateService(unless_exist)
- §8 Jobs: ProcessMatchPointsJob (token idempotente + rescue), ProcessCsvImportJob (csv_file.open + foreach + upsert external_id + rescue failed), RevertMatchPointsJob

## Avisos
- Herda warning Fase 1 (input inferido)
- Riscos: ActiveAdmin × Rails 8.1; Tailwind v4 + config JS
