# TICKET-0014 — Auth (Rails 8 native)

- Deps: TICKET-0001
- Skill: [W]tdd
- MCP: —
- Spec: §6 (admin exige usuário), ADR 0001 §1 (User em core)
- Decisão: `bin/rails generate authentication` (Rails 8 native, sem gem); Devise só se precisar OAuth/confirmable

## Paths
- `app/controllers/{sessions,passwords}_controller.rb`, `app/controllers/concerns/authentication.rb`
- `engines/core/app/models/core/{user,session}.rb` (mover do generator para core)
- `engines/core/db/migrate/*_create_core_sessions.rb`, `spec/requests/sessions_spec.rb`

## Pronto quando
- Login/logout por e-mail + senha (`has_secure_password`); `Current.user` e `Current.ip_address` disponíveis
- `admin` boolean em `core_users` (default false, not null)
- Rotas não públicas exigem sessão (`require_authentication`)

## Teste antes/depois
- Antes: `GET /admin` sem sessão → 200 (ou rota inexistente)
- Depois: sem sessão → redirect `/session/new`; POST credenciais válidas → sessão criada; inválidas → 422
