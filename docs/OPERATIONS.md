# Guia de operações

Setup, admin, seeds, CI, segurança, deploy (Render + Supabase + R2 + Resend), observabilidade e MCPs do Futebol. Índice geral: [docs/README.md](README.md).

## Setup local

### Postgres local

```bash
docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18
bundle install
bin/rails db:prepare db:seed
git config core.hooksPath .githooks
```

`bin/setup` faz o mesmo de forma idempotente: copia `.env.example` para `.env`, sobe ou reinicia o container `futebol-pg` (porta `DB_PORT`, padrão 5440; nome em `DB_CONTAINER`) quando o banco é local, roda `db:prepare` e `db:seed`, compila o CSS (app + ActiveAdmin) e ativa os hooks. `bin/setup --reset` também roda `db:reset`. Sem Docker, suba um Postgres em `localhost:5440` ou defina `DATABASE_URL`.

### Hooks

- `git config core.hooksPath .githooks` ativa o pre-commit (rubocop nos arquivos staged + bloqueio de secrets).
- `.claude/settings.json` bloqueia comandos git destrutivos para agentes (guardrails).

## ActiveAdmin

Admin em ActiveAdmin `4.0.0.beta23`, pinado no Gemfile ([ADR 0002](adr/0002-activeadmin-rails81.md)). É um pré-release: a API pode mudar entre betas, então atualize só de forma deliberada (Gemfile + `bundle update activeadmin` + suíte de `spec/requests/admin`). O fallback estável é a 3.5.x, com Sass/sprockets só para o admin.

- **Login:** [`/admin`](http://localhost:3000/admin) usa a autenticação nativa do Rails 8 (`authenticate_admin_user!`). Sem sessão, redireciona para `/session/new`; usuário logado sem `admin` recebe 403. Em development, o admin do seed é `admin@futebol.dev` / `futebol-admin` (ou `SEED_ADMIN_PASSWORD`).
- **Logout:** o link de logout do cabeçalho do ActiveAdmin envia `DELETE /session` (`config.logout_link_path`), que encerra a sessão e volta para `/session/new`.

## Seeds e login demo

Em development e test, `db:seed` cria dados de demonstração. É idempotente: rodar de novo não duplica registros nem repontua.

- Usuários `demo1@demo.local` … `demo5@demo.local`, senha `demo-futebol`. Admin: `admin@futebol.dev` / `futebol-admin` (ou `SEED_ADMIN_PASSWORD`).
- Bolão `DEMO01` ([`/pools`](http://localhost:3000/pools)), dono `demo1`, com os 5 usuários e 150 palpites nas rodadas 1–10.
- Rodadas 1–4 e 6 finalizadas e pontuadas; rodada 5 ao vivo; rodadas 7–10 agendadas para os próximos domingos (as datas avançam se já tiverem passado).
- Escalação 4-3-3 de `demo1` na rodada 7: [`/lineup?round=7`](http://localhost:3000/lineup?round=7).

Fora de development/test, os dados demo não são criados: a senha acima é pública.

## Filas

- `bin/dev` sobe web + `bin/jobs` (Solid Queue). Development e test usam um banco de fila separado (`futebol_*_queue`), criado por `bin/rails db:prepare`.
- Painel das filas: [`/admin/jobs`](http://localhost:3000/admin/jobs) (mission_control-jobs). Visitante vai para o login; usuário sem `admin` recebe 403 (`JobsDashboardPolicy`).

## Testes e qualidade

- Gate local (o `test` de [`.cursor/environment.json`](../.cursor/environment.json)): `bundle exec rspec && bundle exec rubocop && bundle exec packwerk check && bin/rails zeitwerk:check`.
- System specs (Chrome headless): `bundle exec rspec spec/system`; o CI roda com `RAILS_SYSTEM_TESTING_SCREENSHOT=failed`.
- Schema × models: `bundle exec database_consistency -c config/database_consistency.todo.yml`.
- Antes do PR: `bin/ci` ([`config/ci.rb`](../config/ci.rb)).
- Detalhes das ferramentas e configurações: [QUALITY.md](QUALITY.md).

## Comandos úteis

| Comando | O que faz |
|---|---|
| `bin/setup` | instala gems, prepara `.env`, Postgres local, bancos, seeds, CSS e hooks |
| `bin/dev` | web + Solid Queue + watchers de CSS (app e ActiveAdmin) ([`Procfile.dev`](../Procfile.dev)) |
| `bin/rails db:prepare db:seed` | cria/migra os bancos (primary, queue) e carrega os seeds |
| `bin/rails db:reset` | recria o banco local do zero |
| `bin/jobs` | só o worker do Solid Queue |
| `bin/rails tailwindcss:build` | compila o CSS do app |
| `bin/rails observability:fake_exception` | gera um span de erro e imprime o `trace_id` |
| `bin/ci` | checagens locais antes do PR |

## CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) roda em todo PR e em push para `main` e `tier/**`:

- `lint`: RuboCop, `packwerk validate` + `packwerk check`, `zeitwerk:check`, Brakeman, `bundler-audit check --update` e o grep de design (sem gradient/blur/glow).
- `test`: `db:prepare` (primary + queue) no Postgres 18, `database_consistency`, `bundle exec rspec` (sem `spec/system`), as system specs num step próprio (`RAILS_SYSTEM_TESTING_SCREENSHOT=failed`, screenshots de falha como artifact) e depois `db:seed` duas vezes, falhando se a linha `seeds ok (...)` com as contagens mudar entre as cargas.
- `secrets`: `gitleaks detect` no histórico inteiro. Falsos positivos revisados vão para [`.gitleaksignore`](../.gitleaksignore) (fingerprint por linha).
- `deploy`: só em push para `main`, depois de `lint`, `test` e `secrets`; chama `RENDER_DEPLOY_HOOK_URL` (secret do repositório). Sem o secret, o job avisa e o deploy fica manual.

## Segurança

[Dependabot](../.github/dependabot.yml) abre PRs semanais (segunda-feira) para gems e GitHub Actions. O ActiveAdmin fica de fora porque é um beta pinado. Vulnerabilidades: [SECURITY.md](../SECURITY.md). Licença: [MIT](../LICENSE).

| Ferramenta | Onde roda | Comando local |
|---|---|---|
| gitleaks (secrets no histórico) | CI, job `secrets` | `gitleaks detect --source . --redact --verbose` |
| Brakeman (análise estática) | CI `lint` e `bin/ci` | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` |
| bundler-audit (CVEs de gems) | CI `lint` e `bin/ci` | `bundle exec bundler-audit check --update` |
| importmap audit (CVEs de pacotes JS) | `bin/ci` | `bin/importmap audit` |
| pre-commit | local (`.githooks`) | bloqueia `.env` e `*.key` staged |

## Docker

O [`Dockerfile`](../Dockerfile) é de produção (é o que o Render builda). Para rodar à mão:

```bash
docker build -t futebol .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<valor de config/master.key> --name futebol futebol
```

Development usa Docker só para o Postgres (`futebol-pg`) e, opcionalmente, o OpenObserve (`futebol-openobserve`, ver [Observabilidade](#observabilidade-opentelemetry--openobserve)).

## Deploy (Render + Supabase)

[`render.yaml`](../render.yaml) define `futebol-web` (Docker, Puma + Thruster, health check `/up`) e `futebol-worker` (`./bin/jobs`, Solid Queue). O `bin/docker-entrypoint` roda `db:prepare` no boot do web pela `SUPABASE_DIRECT_URL` e cria `<db>_cache`, `<db>_queue` e `<db>_cable` ao lado do banco principal no Supabase.

Variáveis (grupo `futebol` no Render): `RAILS_MASTER_KEY`, `SUPABASE_DATABASE_URL`, `SUPABASE_DIRECT_URL`, `APP_HOST`, `R2_*`, `RESEND_*`, `OPENOBSERVE_OTLP_ENDPOINT`, `OPENOBSERVE_AUTH` (ver [.env.example](../.env.example)). No plano free, sem worker: remova `futebol-worker` e defina `SOLID_QUEUE_IN_PUMA=1` no web.

Passos manuais (sem credenciais no ambiente do agente):

- manual: criar o Blueprint no Render a partir de `render.yaml` (Dashboard → New → Blueprint) e preencher as variáveis `sync: false`.
- manual: `gh secret set RENDER_DEPLOY_HOOK_URL --body "<deploy hook do futebol-web>"` (ativa o job `deploy` do CI).
- manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` (deploy avulso).
- manual: `curl -fsS https://<app>.onrender.com/up` (espera 200).

### Banco (Supabase)

Production usa Postgres no [Supabase](https://supabase.com); development e test continuam no Postgres local (docker `futebol-pg`). [`config/database.yml`](../config/database.yml) lê `SUPABASE_DATABASE_URL` (ou `DATABASE_URL`, como fallback) e liga `sslmode: require` e `max_connections` de 5 (`RAILS_MAX_THREADS`).

**Pooling:**

| Variável | Conexão (Dashboard → Connect) | Uso | Prepared statements |
|---|---|---|---|
| `SUPABASE_DATABASE_URL` | Transaction pooler, porta **6543** | runtime do web e do worker | **desligados**. O pooler entrega cada transação a qualquer conexão do servidor, então `prepared_statements` e `advisory_locks` ficam `false`, detectados pela porta 6543. |
| `SUPABASE_DIRECT_URL` | Session pooler, porta **5432** (`aws-0-<region>.pooler.supabase.com`) | `db:prepare`/migrations no `bin/docker-entrypoint` | ligados (sessão dedicada; migrations usam advisory lock) |

Motivos da escolha:

- No free tier, o session pooler segura uma conexão do servidor por cliente, num pool de ~15. Web e worker, com 4 pools cada (primary, cache, queue e cable) de até 5 conexões, esgotam esse limite. O transaction pooler multiplexa os clientes.
- A conexão direta (`db.<ref>.supabase.co`) é só IPv6 sem o add-on IPv4, e o Render sai por IPv4. Por isso a "direct URL" aqui é o session pooler.

**Solid Queue/Cache/Cable:** ficam em bancos irmãos no mesmo projeto (`postgres_cache`, `postgres_queue`, `postgres_cable`), criados pelo `db:prepare` (a role `postgres` do Supabase tem `CREATEDB`). `CACHE_/QUEUE_/CABLE_DATABASE_URL` sobrescrevem. Foi mantido o modelo atual, sem consolidar no banco principal: os schemas `db/{cache,queue,cable}_schema.rb` continuam carregados por `db:prepare`, sem migrations copiadas. O custo é que os 4 bancos dividem os 500 MB do free tier, por isso o Solid Cache em production tem `max_size` de 64 MB ([`config/cache.yml`](../config/cache.yml)).

Ensaio local do fluxo (Postgres 18 com SSL + PgBouncer em modo transaction na porta 6543, imitando o pooler):

- `db:prepare` pela URL de sessão criou os 3 bancos irmãos e rodou as migrations.
- Pelo pooler: `db:seed` 2× com contagens iguais, `prepared_statements=false`, `ssl=true`, e Solid Cache, Queue e Cable funcionando.

Passos manuais (o agente não cria o projeto: o MCP do Supabase não está autenticado e não há credenciais no ambiente):

- manual: criar o projeto no [Supabase](https://supabase.com/dashboard) (na região do Render: o `render.yaml` não fixa região, então o padrão é Oregon e o par é `us-west-2`) e guardar a senha do banco.
- manual: em Connect, copiar a URL do **Transaction pooler** (6543) para `SUPABASE_DATABASE_URL` e a do **Session pooler** (5432) para `SUPABASE_DIRECT_URL` no grupo `futebol` do Render, com `?sslmode=require`.
- manual: `SUPABASE_DATABASE_URL="$SUPABASE_DIRECT_URL" RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails db:prepare` (ou o primeiro deploy, que roda o mesmo pelo entrypoint).
- manual: `for i in 1 2; do ALLOW_PRODUCTION_SEED=1 SEED_ADMIN_PASSWORD=<senha forte> RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails db:seed | grep '^seeds ok'; done` (as duas linhas devem ser iguais).

### Pausa por inatividade do Supabase (free tier)

- 500 MB de banco por projeto e 2 projetos ativos por organização.
- O projeto **pausa após 7 dias sem atividade**. O keep-alive do `/up` não toca o banco, então o pause continua possível.
- Para retomar: Dashboard → projeto pausado → **Restore project**. Leva alguns minutos, e a URL e a senha não mudam. Enquanto estiver pausado, o web responde 500 nas páginas que usam o banco, e o `db:prepare` do boot falha.

### Migração Neon → Supabase

Production saiu do Neon para o Supabase. `DATABASE_URL` (Neon) deu lugar a `SUPABASE_DATABASE_URL` (transaction pooler, runtime) e `SUPABASE_DIRECT_URL` (session pooler, `db:prepare`), e `DATABASE_URL` segue aceita só como fallback. As referências ao Neon saíram de `render.yaml`, `.env.example`, `config/database.yml` e [docs/mcp](mcp/README.md). Tickets, checkpoints e handoffs antigos ainda citam o Neon porque registram o que foi feito na época. Detalhes da migração: [STATUS](checkpoints/STATUS.md), seção "Correções e migrações de infra", bloco F.

### Keep-alive

O web free do Render dorme após 15 min sem tráfego. Crie um cron em [cron-job.org](https://cron-job.org) (ou similar):

- URL: `https://<app>.onrender.com/up`, método GET, a cada 10 min (`*/10 * * * *`).
- `/up` é público, não redireciona para HTTPS e não passa pela checagem de host, então o ping não depende de cookie nem de domínio.
- manual: cadastrar o job no cron-job.org e conferir o histórico de execuções (200).

### Storage (Cloudflare R2)

Serviço `r2` em [`config/storage.yml`](../config/storage.yml) (S3 API, `endpoint: https://<R2_ACCOUNT_ID>.r2.cloudflarestorage.com`, `region: auto`). Production usa `r2` com o bucket `futebol-prod`; development usa disco, ou `ACTIVE_STORAGE_SERVICE=r2` para o bucket `futebol-dev`.

- manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod`
- manual: `ACTIVE_STORAGE_SERVICE=r2 bin/rails runner 'puts ActiveStorage::Blob.create_and_upload!(io: StringIO.new("ok"), filename: "smoke.txt").key'` (arquivo visível em `futebol-dev`)

### E-mail (Resend)

Production envia por SMTP (`smtp.resend.com:465`, TLS, usuário `resend`, senha `RESEND_API_KEY`); remetente em `RESEND_FROM`.

- manual: `RAILS_ENV=production bin/rails runner 'ActionMailer::Base.mail(from: ENV["RESEND_FROM"], to: "<voce@exemplo.com>", subject: "Futebol: teste Resend", body: "ok").deliver_now'`

## Observabilidade (OpenTelemetry → OpenObserve)

Traces e logs saem por OTLP/HTTP para o [OpenObserve](https://openobserve.ai) ([`config/initializers/opentelemetry.rb`](../config/initializers/opentelemetry.rb)). Serviço `futebol`; `use_all` instrumenta Rails (Action Pack/View, Active Record, Active Job, e portanto Solid Queue), Rack, PG (SQL ofuscado), Faraday e Net::HTTP. O health check `/up` não gera trace.

O Sentry foi removido (gems `sentry-*`, initializer, rake task, specs e `SENTRY_DSN`): erros agora viram spans no OpenObserve, descritos abaixo.

| Variável | Uso |
|---|---|
| `OPENOBSERVE_OTLP_ENDPOINT` | URL base OTLP de uma organização do OpenObserve (`http://host:5080/api/<org>`); o app acrescenta `/v1/traces` e `/v1/logs`. Vazia: development usa `http://localhost:5080/api/default`, production não exporta e test nunca exporta. |
| `OPENOBSERVE_AUTH` | Valor do header `Authorization`: `Basic <base64 de email:senha>`. Um token base64 sem prefixo recebe `Basic `. |
| `OTEL_SDK_DISABLED` | `true` desliga o SDK (ex.: development sem OpenObserve rodando). |

A porta é a 5080 (HTTP), não a 5081: a 5081 é o OTLP/gRPC do OpenObserve, e o exporter Ruby (`opentelemetry-exporter-otlp`) fala só OTLP/HTTP.

OpenObserve local via Docker (UI em [localhost:5080](http://localhost:5080); a senha precisa ter maiúscula, minúscula, dígito e símbolo):

```bash
docker run -d --name futebol-openobserve -p 5080:5080 -p 5081:5081 \
  -e ZO_ROOT_USER_EMAIL=root@futebol.local -e 'ZO_ROOT_USER_PASSWORD=Futebol-local1' \
  -v futebol-openobserve:/data public.ecr.aws/zinclabs/openobserve:latest
export OPENOBSERVE_AUTH="Basic $(printf 'root@futebol.local:Futebol-local1' | base64)"
bin/dev   # cada request vira um trace (stream "default", aba Traces)
```

- **Erros:** um subscriber do `Rails.error` ([`lib/observability/error_span_subscriber.rb`](../lib/observability/error_span_subscriber.rb)) transforma cada exceção reportada num span `exception <Classe>` com status `ERROR` e os atributos `exception.type`, `exception.message`, `exception.backtrace` (50 linhas), `exception.handled` e o contexto escalar em `error.context.*` (ex.: `match_id`, `scoring_token`). O span é filho do span da request ou do job. Cobre os `Rails.error.report` dos jobs com rescue e as exceções não tratadas que o próprio Rails reporta; cada exceção é reportada uma vez.
- **Teste da integração:** `bin/rails observability:fake_exception` imprime o `trace_id` para buscar no OpenObserve.
- **Logs (abordagem escolhida: OTel logs, sem sidecar):** o Lograge grava uma linha JSON por request no stdout (logs do Render), com `request_id`, `user_id`, `trace_id` e `span_id`. A instrumentação Logger do OTel envia cada linha de log, inclusive a do Lograge, como log record para o mesmo endpoint (`/v1/logs`, stream "default", aba Logs), já ligada ao trace. Não há collector nem sidecar para operar no Render, e o mesmo endpoint e credencial servem traces e logs. O custo: o SDK de logs Ruby ainda é 0.x.
- **Maturidade:** traces estão estáveis (`opentelemetry-sdk` 1.x). Logs (`opentelemetry-logs-sdk` 0.x, instrumentação Logger 0.x) estão em desenvolvimento e a API pode mudar. Métricas ainda não estão configuradas.
- **OpenObserve MCP:** não é usado nesta fase. Se existir no Cursor, fica só documentado em [docs/mcp](mcp/README.md).

## MCPs

| Nome | Instalação | Escopo | Configurado? |
|------|------------|--------|--------------|
| render | MCP hospedado `https://mcp.render.com/mcp` (OAuth via `/add-plugin render` ou `Bearer RENDER_API_KEY`) | serviços, deploys, logs, métricas, env vars | não |
| supabase | `pipx install supabase-mcp-server` (stdio) | consultas e gestão do projeto; não substitui `SUPABASE_DATABASE_URL` | não |
| openobserve | MCP `https://<instância>/api/<org>/mcp` (Basic auth) | traces/logs/alertas — opcional, **não usado nesta fase** | não |
| r2 | `s3-mcp-server` apontando para o endpoint R2 (`AWS_ENDPOINT_URL=https://<account>.r2.cloudflarestorage.com`) | listar/upload/delete em buckets | não |
| resend | MCP remoto `https://mcp.resend.com` (`RESEND_API_KEY`) | envio/teste de e-mail | não |

Smoke tests, variáveis e comandos manuais por MCP: [docs/mcp/README.md](mcp/README.md) · config exemplo: `.cursor/mcp.json.example`.

### Status MCP (nenhum MCP utilizável no ambiente do agente; o plugin Supabase está em `needsAuth`)

| MCP | status | ação |
|---|---|---|
| render | manual | manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` (sem `RENDER_DEPLOY_HOOK_URL`: deploy não executado) |
| supabase | manual | manual: `psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'` |
| openobserve | não usado | UI do OpenObserve (aba Traces/Logs) |
| r2 | manual | manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod` |
| resend | manual | manual: `curl https://api.resend.com/emails` (ver [docs/mcp](mcp/README.md)) |

### Fluxo de deploy com MCP

O deploy em si não depende de MCP. Merge em `main` dispara o CI (`lint`, `test`, `secrets`), e o job `deploy` chama `RENDER_DEPLOY_HOOK_URL`. Os MCPs entram para acompanhar e diagnosticar:

1. **Antes do merge:** o PR precisa estar verde. Se o merge tiver migrations, confira no Supabase MCP o espaço livre (`select pg_size_pretty(sum(pg_database_size(datname))) from pg_database where datname like 'postgres%'`, limite de 500 MB no free tier) e se o projeto não está pausado. Retomar um projeto pausado só é possível no Dashboard.
2. **Deploy:** depois do job `deploy`, peça ao Render MCP o histórico de deploys do `futebol-web` (`list_deploys`) até o status `live`. O `bin/docker-entrypoint` roda `db:prepare` (migrations) por `SUPABASE_DIRECT_URL` antes do Puma subir. O hook é só do `futebol-web`. O `futebol-worker` (`autoDeploy: false`) precisa de um deploy próprio depois que o web estiver `live`: peça ao Render MCP o deploy do `futebol-worker` (ou use o Dashboard) e acompanhe da mesma forma.
3. **Verificação:**
   - Render MCP: logs de erro dos últimos 15 min do `futebol-web` e do `futebol-worker`, e métricas de respostas por status code (5xx);
   - Supabase MCP, só leitura: `select max(version) from schema_migrations` igual à última migration de `db/migrate`;
   - `curl -fsS https://<app>.onrender.com/up` responde 200;
   - OpenObserve, pela UI: spans `exception *` com status `ERROR` desde o deploy.
4. **Problema:** rollback pelo Dashboard do Render (Deploys → Rollback). O MCP só dispara deploys novos. Migration destrutiva não tem rollback automático, por isso o `strong_migrations` bloqueia as perigosas.
5. **Configuração:** env vars novas entram pelo Dashboard do Render (grupo `futebol`). O MCP também consegue, mas substitui o conjunto inteiro do serviço e pode expor valores no contexto do agente.

**Secrets:** nenhum secret fica no repositório. As credenciais dos MCPs (`RENDER_API_KEY`, `SUPABASE_*`, `QUERY_API_KEY`) ficam no dashboard do Cursor: Settings → MCP, ou OAuth do plugin, no IDE; Cloud Agents → Secrets para agentes na nuvem. As do app (`RAILS_MASTER_KEY`, `SUPABASE_DATABASE_URL`, `OPENOBSERVE_AUTH`, …) ficam no Render. O `.cursor/mcp.json.example` só referencia `${env:VAR}`, e o gitleaks do CI barra commits com credenciais. Detalhes por MCP: [docs/mcp/README.md](mcp/README.md).
