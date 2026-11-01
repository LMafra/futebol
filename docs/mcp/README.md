# MCPs — instalação, escopo e smoke tests

- Config de exemplo, sem segredos: [`.cursor/mcp.json.example`](../../.cursor/mcp.json.example). Copie para `.cursor/mcp.json`; os valores usam só `${env:VAR}`.
- **Nenhum secret no repositório.** Tokens e senhas dos MCPs (`RENDER_API_KEY`, `SUPABASE_*`, `QUERY_API_KEY`, token do OpenObserve) ficam no dashboard do Cursor: Settings → MCP (ou OAuth do plugin) no IDE, e Cloud Agents → Secrets para agentes na nuvem. Os secrets do app ficam no grupo `futebol` do Render. O gitleaks do CI (job `secrets`) barra commits com credenciais.
- Variáveis do app: [`.env.example`](../../.env.example).
- Regra: MCPs só são chamados quando um ticket pede explicitamente, nunca para explorar.

## Resumo

| MCP | Transporte / endpoint | Escopo | Status no ambiente do agente (2026-11-01) | Smoke test (MCP) | Comando manual equivalente |
|---|---|---|---|---|---|
| render | HTTP hospedado `https://mcp.render.com/mcp` | serviços, deploys, logs, métricas, env vars | conectado (plugin do Cursor; workspace `tea-cspqio56l47c739ns4ug`) | `list_services` | `curl -fsS -H "Authorization: Bearer $RENDER_API_KEY" https://api.render.com/v1/services?limit=20` |
| supabase | plugin oficial do Cursor; alternativa stdio `pipx install supabase-mcp-server` | consultas e gestão do projeto; **não** substitui `SUPABASE_DATABASE_URL` | conectado (plugin do Cursor) | `list_projects` / `execute_sql` | `docker run --rm postgres:18 psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'` |
| openobserve (opcional) | HTTP `https://<instância>/api/<org>/mcp` | consultar traces/logs, alertas | **não usado nesta fase** (só documentado) | — | UI do OpenObserve, aba Traces |
| r2 | stdio `s3-mcp-server` | buckets `futebol-dev` / `futebol-prod` | não configurado | `list_buckets` | `aws s3api list-buckets --endpoint-url "$R2_ENDPOINT"` |
| resend | HTTP `https://mcp.resend.com/mcp` | e-mail de teste | não configurado | `send-email` p/ endereço de teste | `curl -fsS https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -H 'Content-Type: application/json' -d '{"from":"onboarding@resend.dev","to":"delivered@resend.dev","subject":"futebol smoke","text":"ok"}'` |

## render

Servidor oficial e hospedado ([docs](https://render.com/docs/mcp-server)): `https://mcp.render.com/mcp`.

- **Instalação no Cursor:**
  - OAuth: `/add-plugin render` numa janela do agente, depois Authenticate.
  - API key: entrada `render` do `.cursor/mcp.json.example` (`Authorization: Bearer ${env:RENDER_API_KEY}`, chave criada em Account Settings → API Keys).
- **Primeiro passo:** definir o workspace ("Set my Render workspace to …"). Todas as ações valem para o workspace selecionado.
- **Serviços:** listar, ver detalhes e criar web service, static site, cron job, Render Postgres e Key Value.
  - **Não** cria background worker nem Blueprint. O `futebol-worker` e o Blueprint de [`render.yaml`](../../render.yaml) continuam sendo criados no Dashboard.
- **Deploys:** disparar um novo deploy (opcionalmente limpando o cache de build), listar o histórico e ver detalhes. Rollback não existe no MCP: use o Dashboard (Deploys → Rollback).
- **Logs:** buscar por filtros (serviço, nível, texto, intervalo) e listar os valores de um label.
- **Métricas:** CPU e memória, instâncias, conexões, respostas por status code, banda de saída. Tempo de resposta só no plano Pro.
- **Env vars:** "update all environment variables" **substitui o conjunto inteiro** do serviço. Prefira o Dashboard para secrets: o MCP pode expor valores no contexto do agente.
- **Smoke:** `list_services` deve devolver `futebol-web`/`futebol-worker` (lista vazia é ok antes do Blueprint) sem 401.
- **Deploy manual:** `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"`.

## supabase

Servidor da comunidade, por stdio ([PyPI](https://pypi.org/project/supabase-mcp-server/)).

- **Instalação:** `pipx install supabase-mcp-server`. A entrada `supabase` do `.cursor/mcp.json.example` roda o comando `supabase-mcp-server`.
- **Env:**
  - obrigatórias: `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`, `SUPABASE_REGION` (região errada dá "Tenant or user not found") e `QUERY_API_KEY` (chave de thequery.dev, exigida pelo servidor);
  - opcionais: `SUPABASE_ACCESS_TOKEN` (Management API) e `SUPABASE_SERVICE_ROLE_KEY` (Auth Admin; não precisamos).
  Instalado via pipx, o servidor **não lê** o `.env` do projeto: as variáveis vêm do Cursor ou do arquivo de config global do servidor.
- **Conexão:** o servidor usa só o transaction pooler (6543). **Session pooling não é suportado.**
- **Escopo: consultas e gestão, nunca a conexão do app.** O app conecta por `SUPABASE_DATABASE_URL`/`SUPABASE_DIRECT_URL` (docs/OPERATIONS.md, seção "Banco (Supabase)"). Migrations rodam pelo `db:prepare` do entrypoint, não pelo MCP, para o histórico ficar em `db/migrate`.
- **Smoke:** `get_schemas` deve listar `public` com as tabelas do app.
- **Manual sem psql local:** `docker run --rm postgres:18 psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'`.
- O plugin oficial do Supabase no Cursor está autenticado desde 2026-11-01 e foi o usado no deploy (`list_projects`, `create_project`, `execute_sql`, `list_tables`, `list_extensions`). O servidor stdio acima continua sendo a alternativa documentada; ele não substitui a connection string do app.

## Comandos usados no deploy (2026-11-01)

Plugins do Cursor, não o servidor stdio. Nenhum secret entra nestes comandos. Fallback é o Dashboard ou a API, sem colar senha no chat.

| MCP | Ferramenta | Fallback manual |
|---|---|---|
| Supabase | `list_projects` | Dashboard → lista de projetos |
| Supabase | `pause_project` | Dashboard → Pause project |
| Supabase | `create_project` (`get_cost` + `confirm_cost` se a ferramenta pedir) | Dashboard → New project. O MCP não aceita `db_pass` e não devolve a senha: `PATCH /v1/projects/{ref}/database/password` e gravar a URI fora do repo |
| Supabase | `get_project` / `get_project_url` | Dashboard → Project Settings → API |
| Supabase | `execute_sql` | SQL Editor, ou `docker run --rm postgres:18 psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'` |
| Supabase | `list_extensions` | SQL Editor: `SELECT name, installed_version FROM pg_available_extensions WHERE name IN ('pgcrypto','plpgsql')` |
| Supabase | `list_tables` | SQL Editor: `\dt` ou `select tablename from pg_tables where schemaname = 'public'` |
| Render | `list_workspaces` | Dashboard → troca de workspace. Há um só: `tea-cspqio56l47c739ns4ug` |
| Render | `list_services` | `curl -fsS -H "Authorization: Bearer $RENDER_API_KEY" https://api.render.com/v1/services?limit=20` |
| Render | `create_web_service` | Dashboard → New → Web Service. O MCP não cria background worker |
| Render | `update_environment_variables` | Dashboard → Environment. Neste deploy os segredos foram por `PUT /v1/services/{id}/env-vars` (merge), para os valores não irem ao transcript |
| Render | `trigger_deploy` | Dashboard → Manual Deploy, ou `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` |
| Render | `list_deploys` | Dashboard → Deploys |
| Render | `list_logs` | Dashboard → Logs (build e runtime) |

## openobserve (opcional, não usado nesta fase)

O OpenObserve expõe um MCP próprio ([docs](https://openobserve.ai/docs/integration/ai/mcp/)) em `https://<instância>/api/<org>/mcp` (a instância self-hosted de `docker/openobserve/docker-compose.yml`; localmente, `http://localhost:5080/api/default/mcp`), autenticado por `Authorization: Basic <base64 de email:senha>`, o mesmo valor do `authorization` em `OTEL_EXPORTER_OTLP_HEADERS`. Ele serve para consultar traces e logs em linguagem natural e para criar alertas.

Nesta fase ele **não é usado nem configurado**, e não está no `.cursor/mcp.json.example`. Para ativar no futuro, adicione ao `.cursor/mcp.json` local:

```json
"openobserve": {
  "url": "https://<instância>/api/<org>/mcp",
  "headers": { "Authorization": "Basic ${env:OPENOBSERVE_MCP_TOKEN}" }
}
```

## r2
- Instalação: `s3-mcp-server` com `AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL=$R2_ENDPOINT`, `AWS_REGION=auto`
- Env: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`, `R2_BUCKET_DEV`, `R2_BUCKET_PROD`
- Escopo: listar/upload/delete nos buckets do projeto
- Smoke: `list_buckets` → esperado `futebol-dev` e `futebol-prod`
- Criar buckets manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod`

## resend
- Instalação: MCP remoto `https://mcp.resend.com/mcp` com `RESEND_API_KEY`
- Env: `RESEND_API_KEY`, `RESEND_FROM`
- Escopo: envio/teste de e-mail (sem listas de contatos)
- Smoke: `send-email` para `delivered@resend.dev` → esperado id do e-mail

## DB local (development/test)
- `bin/setup` sobe `futebol-pg` (docker, porta 5440) automaticamente
- Manual: `docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18`
