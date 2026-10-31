# TICKET-0004 — (d) ProcessMatchPointsJob + Scoring::Engine (scoring_token idempotente)

- Deps: TICKET-0003
- Skill: [W]tdd
- MCP: —
- Spec: §7 (Scoring::Engine), §8

## Paths
- `app/services/scoring/engine.rb`, `app/jobs/process_match_points_job.rb`
- `engines/bolao/db/migrate/*` (prediction_scores unique `(prediction_id, scoring_token)`)
- `spec/services/scoring/engine_spec.rb`, `spec/jobs/process_match_points_job_spec.rb`

## Pronto quando
- Engine puro: 10/7/5/3/0
- Job no-op se `match.scoring_token == scoring_token`; insert em lote + `mark_scored!`
- `rescue StandardError` → log + `Sentry.capture_exception` + re-raise

## Teste antes/depois
- Antes: perform 2× com mesmo token gera pontos duplicados
- Depois: `expect { 2.times { perform(match.id, token) } }.to change(PredictionScore, :count).by(predictions.size)`; erro simulado → Sentry chamado e exceção propagada
