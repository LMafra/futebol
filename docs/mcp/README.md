# MCPs — instalação, escopo e smoke tests

- Config de exemplo (sem segredos): [`.cursor/mcp.json.example`](../../.cursor/mcp.json.example) → copiar para `.cursor/mcp.json` (não versionar segredos; usa `${env:VAR}`)
- Variáveis: ver [`.env.example`](../../.env.example)
- Regra: MCPs só são chamados quando um ticket pede explicitamente; nunca para explorar
- Status em 2026-10-31 (TICKET-0013): nenhum MCP configurado → smoke tests **não executados**; status = `manual`

## Resumo

| MCP | escopo | configurado? | smoke test (MCP) | status smoke | comando manual equivalente |
|---|---|---|---|---|---|
| neon | Postgres **dev/test apenas** (NUNCA prod) | não | `run_sql` → `SELECT 1` na branch dev | manual | `psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'` |
| render | deploy, logs, serviços | não | `list_services` | manual | `curl -fsS -H "Authorization: Bearer $RENDER_API_KEY" https://api.render.com/v1/services?limit=20` |
| r2 | buckets `futebol-dev` / `futebol-prod` | não | `list_buckets` | manual | `aws s3api list-buckets --endpoint-url "$R2_ENDPOINT"` |
| resend | e-mail de teste | não | `send-email` p/ endereço de teste | manual | `curl -fsS https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -H 'Content-Type: application/json' -d '{"from":"onboarding@resend.dev","to":"delivered@resend.dev","subject":"futebol smoke","text":"ok"}'` |

## neon
- Instalação: `npx -y @neondatabase/mcp-server-neon start "$NEON_API_KEY"` (ou remoto `https://mcp.neon.tech/mcp`)
- Env: `NEON_API_KEY`, `NEON_DEV_DATABASE_URL`
- Escopo: restringir a projeto/branch de dev; produção usa `DATABASE_URL` no Render, nunca via MCP
- Smoke: `run_sql` com `SELECT 1` → esperado `1`
- Manual sem psql local: `docker run --rm postgres:18 psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'`

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

## DB local (substitui neon enquanto não configurado)
- `bin/setup` sobe `futebol-pg` (docker, porta 5440) automaticamente
- Manual: `docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18`
