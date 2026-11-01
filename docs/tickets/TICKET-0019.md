# TICKET-0019 — Rate limiting em auth endpoints

- Deps: TICKET-0014
- Skill: [C]surgical-patch, [W]tdd
- MCP: —
- Spec: §9 (não-funcionais)

## Paths
- `app/controllers/sessions_controller.rb`, `app/controllers/passwords_controller.rb`
- `spec/requests/rate_limit_spec.rb`

## Pronto quando
- `rate_limit to: 10, within: 3.minutes, only: :create` (Rails 8 native, backend Solid Cache)
- Excesso → 429 + mensagem amigável; tentativa logada (lograge) com IP

## Teste antes/depois
- Antes: 50 POST `/session` seguidos → todos 422
- Depois: 11º POST na janela → 429; após `travel 3.minutes` → volta a aceitar
