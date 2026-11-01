# MCPs — instalação, escopo e smoke tests

- Config de exemplo, sem segredos: [`.cursor/mcp.json.example`](../../.cursor/mcp.json.example). Copie para `.cursor/mcp.json`; os valores usam só `${env:VAR}`.
- **Nenhum secret no repositório.** Tokens e senhas dos MCPs (`RENDER_API_KEY`, `SUPABASE_*`, `QUERY_API_KEY`, token do OpenObserve) ficam no dashboard do Cursor: Settings → MCP (ou OAuth do plugin) no IDE, e Cloud Agents → Secrets para agentes na nuvem. Os secrets do app ficam no grupo `futebol` do Render. O gitleaks do CI (job `secrets`) barra commits com credenciais.
- Variáveis do app: [`.env.example`](../../.env.example).
- Regra: MCPs só são chamados quando um ticket pede explicitamente, nunca para explorar.

## Resumo

| MCP | Transporte / endpoint | Escopo | Status no ambiente do agente (2026-10-31) | Smoke test (MCP) | Comando manual equivalente |
|---|---|---|---|---|---|
| render | HTTP hospedado `https://mcp.render.com/mcp` | serviços, deploys, logs, métricas, env vars | não configurado | `list_services` | `curl -fsS -H "Authorization: Bearer $RENDER_API_KEY" https://api.render.com/v1/services?limit=20` |
| supabase | stdio, `pipx install supabase-mcp-server` | consultas e gestão do projeto; **não** substitui `SUPABASE_DATABASE_URL` | plugin Supabase do Cursor em `needsAuth` | `get_schemas` | `psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'` |
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
- O plugin oficial do Supabase no Cursor (MCP hospedado) aparece neste ambiente como `needsAuth`. Autenticar exige login no IDE, então nada foi chamado.

## openobserve (opcional, não usado nesta fase)

O OpenObserve expõe um MCP próprio ([docs](https://openobserve.ai/docs/integration/ai/mcp/)) em `https://<instância>/api/<org>/mcp` (Cloud: `https://api.openobserve.ai/api/<org>/mcp`), autenticado por `Authorization: Basic <base64 de email:senha>`, o mesmo valor de `OPENOBSERVE_AUTH`. Ele serve para consultar traces e logs em linguagem natural e para criar alertas.

Nesta fase ele **não é usado nem configurado**, e não está no `.cursor/mcp.json.example`. Para ativar no futuro, adicione ao `.cursor/mcp.json` local:

```json
"openobserve": {
  "url": "https://api.openobserve.ai/api/<org>/mcp",
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
