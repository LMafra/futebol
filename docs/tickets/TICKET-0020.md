# TICKET-0020 — bin/setup + .env.example

- Deps: TICKET-0001
- Skill: [C]lean-build
- MCP: —
- Spec: §9; `docs/mcp/README.md` (DB local)

## Paths
- `bin/setup`, `.env.example` (já liberado no `.gitignore` via `!/.env.example`)

## Pronto quando
- `bin/setup`: sobe `futebol-pg` (docker, porta 5440) se ausente → `bundle install` → `db:prepare` → `db:seed` → `git config core.hooksPath .githooks`; idempotente
- `.env.example`: DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, SENTRY_DSN, RESEND_API_KEY, R2 (AWS_*), RENDER_DEPLOY_HOOK_URL, NEON_DEV_DATABASE_URL — sem valores reais

## Teste antes/depois
- Antes: setup manual em 4 comandos (README)
- Depois: clone limpo + `bin/setup` 2× → exit 0 nas duas; `bin/rails db:seed` imprime saída esperada
