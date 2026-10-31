# TICKET-0010 — (j) ActiveAdmin pages + Pundit (5 policies)

- Deps: TICKET-0005, TICKET-0006, TICKET-0007, TICKET-0009
- Skill: [W]tdd
- MCP: —
- Spec: §6

## Paths
- `app/admin/{matches,csv_imports,pools,squads,audit_logs,scoring_dashboard}.rb`
- `app/policies/{match,csv_import,pool,squad,audit_log}_policy.rb`
- `config/initializers/active_admin.rb` (`authorization_adapter = ActiveAdmin::PunditAdapter`)
- `spec/policies/*_policy_spec.rb`, `spec/requests/admin/*_spec.rb`

## Pronto quando
- Cada action/member_action com `authorize`; `revert?`/`preview?`/`import?` explícitos
- AuditLog read-only (create/update/destroy → false)

## Teste antes/depois
- Antes: usuário não-admin acessa `PUT /admin/matches/:id/revert` (200)
- Depois: policy specs por action; request spec não-admin → redirect/403; admin → revert enfileira RevertMatchPointsJob
