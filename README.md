# Futebol

[![CI](https://github.com/LMafra/futebol/actions/workflows/ci.yml/badge.svg)](https://github.com/LMafra/futebol/actions/workflows/ci.yml)

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

## Filas e erros

- `bin/dev` sobe web + `bin/jobs` (Solid Queue). Development e test usam um banco de fila separado (`futebol_*_queue`), criado por `bin/rails db:prepare`.
- Painel das filas: [`/admin/jobs`](http://localhost:3000/admin/jobs) (mission_control-jobs). Visitante vai para o login; usuário sem `admin` recebe 403 (`JobsDashboardPolicy`).
- Sentry: DSN em `SENTRY_DSN` ([.env.example](.env.example)), `send_default_pii = false`. Sem DSN em development, os eventos vão para `log/sentry_debug_events.log`.
- Teste da integração: `bin/rails sentry:fake_exception` (imprime o `event_id` e o destino).

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) roda em todo PR e em push para `main` e `tier/**`:

- `lint`: RuboCop, Packwerk, `zeitwerk:check`, Brakeman e o grep de design (sem gradient/blur/glow).
- `test`: `db:prepare` (primary + queue) no Postgres 18 e `bundle exec rspec`.
- `deploy`: só em push para `main`, depois de `lint` e `test`; chama `RENDER_DEPLOY_HOOK_URL` (secret do repositório). Sem o secret, o job avisa e o deploy fica manual.

## Deploy (Render + Neon)

[`render.yaml`](render.yaml) define `futebol-web` (Docker, Puma + Thruster, health check `/up`) e `futebol-worker` (`./bin/jobs`, Solid Queue). O `bin/docker-entrypoint` roda `db:prepare` no boot do web e cria `<db>_cache`, `<db>_queue` e `<db>_cable` ao lado do banco do `DATABASE_URL` no Neon.

Variáveis (grupo `futebol` no Render): `RAILS_MASTER_KEY`, `DATABASE_URL`, `APP_HOST`, `R2_*`, `RESEND_*`, `SENTRY_DSN` (ver [.env.example](.env.example)). No plano free, sem worker: remova `futebol-worker` e defina `SOLID_QUEUE_IN_PUMA=1` no web.

Passos manuais (sem credenciais no ambiente do agente):

- manual: criar o Blueprint no Render a partir de `render.yaml` (Dashboard → New → Blueprint) e preencher as variáveis `sync: false`.
- manual: `gh secret set RENDER_DEPLOY_HOOK_URL --body "<deploy hook do futebol-web>"` (ativa o job `deploy` do CI).
- manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` (deploy avulso).
- manual: `curl -fsS https://<app>.onrender.com/up` (espera 200).

### Keep-alive

O web free do Render dorme após 15 min sem tráfego. Crie um cron em [cron-job.org](https://cron-job.org) (ou similar):

- URL: `https://<app>.onrender.com/up`, método GET, a cada 10 min (`*/10 * * * *`).
- `/up` é público, não redireciona para HTTPS e não passa pela checagem de host, então o ping não depende de cookie nem de domínio.
- manual: cadastrar o job no cron-job.org e conferir o histórico de execuções (200).

### Storage (Cloudflare R2)

Serviço `r2` em [`config/storage.yml`](config/storage.yml) (S3 API, `endpoint: https://<R2_ACCOUNT_ID>.r2.cloudflarestorage.com`, `region: auto`). Production usa `r2` com o bucket `futebol-prod`; development usa disco, ou `ACTIVE_STORAGE_SERVICE=r2` para o bucket `futebol-dev`.

- manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod`
- manual: `ACTIVE_STORAGE_SERVICE=r2 bin/rails runner 'puts ActiveStorage::Blob.create_and_upload!(io: StringIO.new("ok"), filename: "smoke.txt").key'` (arquivo visível em `futebol-dev`)

### E-mail (Resend)

Production envia por SMTP (`smtp.resend.com:465`, TLS, usuário `resend`, senha `RESEND_API_KEY`); remetente em `RESEND_FROM`.

- manual: `RAILS_ENV=production bin/rails runner 'ActionMailer::Base.mail(from: ENV["RESEND_FROM"], to: "<voce@exemplo.com>", subject: "Futebol: teste Resend", body: "ok").deliver_now'`

## MCPs

| Nome | Instalação | Escopo | Configurado? |
|------|------------|--------|--------------|
| neon | `npx -y @neondatabase/mcp-server-neon start <NEON_API_KEY>` (MCP oficial) | Postgres apenas em dev/test — nunca em produção | não |
| render | `render-useful-mcp` (servidor MCP com `RENDER_API_KEY`) | deploy, logs, serviços | não |
| r2 | `s3-mcp-server` apontando para o endpoint R2 (`AWS_ENDPOINT_URL=https://<account>.r2.cloudflarestorage.com`) | listar/upload/delete em buckets | não |
| resend | MCP remoto `https://mcp.resend.com` (`RESEND_API_KEY`) | envio/teste de e-mail | não |

Smoke tests, variáveis e comandos manuais por MCP: [docs/mcp/README.md](docs/mcp/README.md) · config exemplo: `.cursor/mcp.json.example`.

### Status MCP (TIER-6 — nenhum MCP disponível no ambiente do agente)

| MCP | status | ação |
|---|---|---|
| neon | manual | manual: `psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'` |
| render | manual | manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` (sem `RENDER_DEPLOY_HOOK_URL`: deploy não executado) |
| r2 | manual | manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod` |
| resend | manual | manual: `curl https://api.resend.com/emails` (ver [docs/mcp](docs/mcp/README.md)) |

## Hooks

- `git config core.hooksPath .githooks` ativa o pre-commit (rubocop nos arquivos staged + bloqueio de secrets).
- `.claude/settings.json` bloqueia comandos git destrutivos para agentes (guardrails).
