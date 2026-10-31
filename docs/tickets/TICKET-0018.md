# TICKET-0018 — Users::AnonymizeService (LGPD)

- Deps: TICKET-0014
- Skill: [W]tdd
- MCP: —
- Spec: §2 (`audit_logs.ip_address`), ADR 0001 §1

## Paths
- `app/services/users/anonymize_service.rb`
- `spec/services/users/anonymize_service_spec.rb`

## Pronto quando
- `call(user:, actor:, ip_address:)` em transação: e-mail → `anon-<uuid>@invalid`, nome → "Usuário anonimizado", `password_digest` invalidado, sessões destruídas
- Predictions/scores mantidos (ranking histórico) sem PII
- AuditLog `action: 'anonymize'` com `ip_address`; idempotente (2ª chamada no-op)

## Teste antes/depois
- Antes: serviço inexistente; dados pessoais permanecem
- Depois: nenhum campo PII original no registro; login antigo falha; `expect { 2.times { call } }.to change(Core::AuditLog, :count).by(1)`
