# TICKET-0005 — (e) RevertMatchPointsService + RevertMatchPointsJob (discard + AuditLog ip_address)

- Deps: TICKET-0003, TICKET-0004
- Skill: [W]tdd
- MCP: —
- Spec: §7, §8; ADR §2

## Paths
- `app/services/revert_match_points_service.rb`, `app/jobs/revert_match_points_job.rb`
- `engines/core/app/models/core/audit_log.rb`
- `spec/services/revert_match_points_service_spec.rb`

## Pronto quando
- Transação: `PredictionScore.kept.where(scoring_token:).discard_all` + `AuditLog.create!(action: 'revert', ip_address:, actor:)`
- Job no-op se `reversal_token` já aplicado
- `ip_address` obrigatório (inet not null)

## Teste antes/depois
- Antes: revert apaga scores (hard delete) e não audita
- Depois: scores `discarded?` true, `PredictionScore.kept` vazio; 1 AuditLog com `ip_address`; falha no AuditLog → rollback (scores continuam kept)
