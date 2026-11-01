# MCPs — instalação, escopo e smoke tests

- Config de exemplo (sem segredos): [`.cursor/mcp.json.example`](../../.cursor/mcp.json.example) → copiar para `.cursor/mcp.json` (não versionar segredos; usa `${env:VAR}`)
- Variáveis: ver [`.env.example`](../../.env.example)
- Regra: MCPs só são chamados quando um ticket pede explicitamente; nunca para explorar
- Status em 2026-10-31 (TICKET-0013): nenhum MCP configurado → smoke tests **não executados**; status = `manual`

## Resumo

| MCP | escopo | configurado? | smoke test (MCP) | status smoke | comando manual equivalente |
|---|---|---|---|---|---|
| supabase | consultas e gestão do projeto Supabase (não é a conexão do app) | não | `get_schemas` | manual | `psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'` |
| render | deploy, logs, serviços | não | `list_services` | manual | `curl -fsS -H "Authorization: Bearer $RENDER_API_KEY" https://api.render.com/v1/services?limit=20` |
| r2 | buckets `futebol-dev` / `futebol-prod` | não | `list_buckets` | manual | `aws s3api list-buckets --endpoint-url "$R2_ENDPOINT"` |
| resend | e-mail de teste | não | `send-email` p/ endereço de teste | manual | `curl -fsS https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -H 'Content-Type: application/json' -d '{"from":"onboarding@resend.dev","to":"delivered@resend.dev","subject":"futebol smoke","text":"ok"}'` |

## supabase
- Instalação: `pipx install supabase-mcp-server` (stdio)
- Env: `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`, `SUPABASE_REGION`, `QUERY_API_KEY` (obrigatórias); `SUPABASE_ACCESS_TOKEN` (Management API, opcional)
- Escopo: consultas e gestão; o app conecta por `SUPABASE_DATABASE_URL`/`SUPABASE_DIRECT_URL` no Render, nunca via MCP
- Smoke: `get_schemas` → esperado `public` com as tabelas do app
- Manual sem psql local: `docker run --rm postgres:18 psql "$SUPABASE_DIRECT_URL" -c 'SELECT 1'`

## render
- Instalação: `render-useful-mcp` com `RENDER_API_KEY`
- Env: `RENDER_API_KEY`, `RENDER_DEPLOY_HOOK_URL`
- Escopo: listar serviços, logs, disparar deploy
- Smoke: `list_services` → esperado lista (vazia ok) sem erro 401
- Deploy manual: `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"`

## r2
- Instalação: `s3-mcp-server` com `AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL=$R2_ENDPOINT`, `AWS_REGION=auto`
- Env: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`, `R2_BUCKET_DEV`, `R2_BUCKET_PROD`
- Escopo: listar/upload/delete nos buckets do projeto
- Smoke: `list_buckets` → esperado `futebol-dev` e `futebol-prod`
- Criar buckets manual: `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod`

## resend
- Instalação: MCP remoto `https://mcp.resend.com` com `RESEND_API_KEY`
- Env: `RESEND_API_KEY`, `RESEND_FROM`
- Escopo: envio/teste de e-mail (sem listas de contatos)
- Smoke: `send-email` para `delivered@resend.dev` → esperado id do e-mail

## DB local (development/test)
- `bin/setup` sobe `futebol-pg` (docker, porta 5440) automaticamente
- Manual: `docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18`
