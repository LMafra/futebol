# TICKET-0015 — Pundit base + 5 policies vazias

- Deps: TICKET-0014
- Skill: [W]tdd
- MCP: —
- Spec: §1 (pundit ~> 2.5), §6; ADR 0001 §5

## Paths
- `Gemfile` (`pundit ~> 2.5`), `app/controllers/application_controller.rb`
- `app/policies/application_policy.rb` + `{match,csv_import,pool,squad,audit_log}_policy.rb` (já existem como PORO no scaffold)
- `spec/policies/application_policy_spec.rb`

## Pronto quando
- `include Pundit::Authorization`; `pundit_user` = `Current.user`
- `after_action :verify_authorized` (exceto index → `verify_policy_scope`)
- `Pundit::NotAuthorizedError` → flash + redirect (HTML) / 403 (JSON)
- 5 policies herdam deny-all de ApplicationPolicy; `Scope#resolve` → `scope.none`

## Teste antes/depois
- Antes: action sem `authorize` não falha
- Depois: spec de controller sem `authorize` → `Pundit::AuthorizationNotPerformedError`; policy specs: todas as actions false para usuário comum
