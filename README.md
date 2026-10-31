# Futebol

Plataforma Rails 8 com engines `core`, `bolao`, `cartola` e `simulador`.

- Monolito modular Rails 8.1 + Postgres; engines dependem só de `core` ([ADR 0001](docs/adr/0001-arch.md))
- Pontuação idempotente (`scoring_token`) e reversível (`revert_match!` reverte antes de zerar `scores_calculated_at`)
- Design "Placar de Domingo": verde-campo, laranja-cartola, Fraunces + Source Sans 3 ([direção](docs/design/0001-direction.md), [crítica](docs/design/0001-critique.md))
- Escopo e contratos em [spec](docs/spec.md); trabalho em 13 tickets ([INDEX](docs/tickets/INDEX.md))
- Infra: Render + Neon + R2 + Resend ([MCPs](docs/mcp/README.md)); status das fases em [STATUS](docs/checkpoints/STATUS.md)

## Setup local

```bash
docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18
bundle install
bin/rails db:prepare db:seed
git config core.hooksPath .githooks
```

## MCPs

| Nome | Instalação | Escopo | Configurado? |
|------|------------|--------|--------------|
| neon | `npx -y @neondatabase/mcp-server-neon start <NEON_API_KEY>` (MCP oficial) | Postgres apenas em dev/test — nunca em produção | não |
| render | `render-useful-mcp` (servidor MCP com `RENDER_API_KEY`) | deploy, logs, serviços | não |
| r2 | `s3-mcp-server` apontando para o endpoint R2 (`AWS_ENDPOINT_URL=https://<account>.r2.cloudflarestorage.com`) | listar/upload/delete em buckets | não |
| resend | MCP remoto `https://mcp.resend.com` (`RESEND_API_KEY`) | envio/teste de e-mail | não |

Smoke tests, variáveis e comandos manuais por MCP: [docs/mcp/README.md](docs/mcp/README.md) · config exemplo: `.cursor/mcp.json.example`.

### Status MCP (Fase 6 — deploy bootstrap)

| MCP | status | ação |
|---|---|---|
| neon | manual | manual: `psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'` |
| render | manual | manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` |
| r2 | manual | manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod` |
| resend | manual | manual: `curl https://api.resend.com/emails` (ver [docs/mcp](docs/mcp/README.md)) |

## Hooks

- `git config core.hooksPath .githooks` ativa o pre-commit (rubocop nos arquivos staged + bloqueio de secrets).
- `.claude/settings.json` bloqueia comandos git destrutivos para agentes (guardrails).
