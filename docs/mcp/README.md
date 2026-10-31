# MCPs — instalação, escopo e smoke tests

Status em 2026-10-31 (Fase 6): nenhum MCP configurado na sessão → todos **manual**. Smoke tests automatizados: TICKET-0013.

| MCP | escopo | status | comando manual equivalente |
|---|---|---|---|
| neon | dev/test apenas (NUNCA prod) | manual | `psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'` |
| render | deploy, logs, serviços | manual | `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` (ou `render deploys create <service-id>`) |
| r2 | buckets futebol-dev / futebol-prod | manual | `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod` |
| resend | e-mail de teste | manual | `curl -fsS https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -H 'Content-Type: application/json' -d '{"from":"onboarding@resend.dev","to":"<seu-email>","subject":"futebol smoke","text":"ok"}'` |

## Instalação (Cursor: `.cursor/mcp.json`, sem segredos no repo)
- neon: `npx -y @neondatabase/mcp-server-neon start $NEON_API_KEY` — restringir a projeto/branch de dev
- render: `render-useful-mcp` com `RENDER_API_KEY`
- r2: `s3-mcp-server` com `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL=https://<account_id>.r2.cloudflarestorage.com`, `AWS_REGION=auto`
- resend: MCP remoto `https://mcp.resend.com` com `RESEND_API_KEY`

## DB local (substitui neon enquanto não configurado)
- `docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18`
