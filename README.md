# Futebol

Plataforma Rails 8 com engines `core`, `bolao`, `cartola` e `simulador`.

## MCPs

| Nome | Instalação | Escopo | Configurado? |
|------|------------|--------|--------------|
| neon | `npx -y @neondatabase/mcp-server-neon start <NEON_API_KEY>` (MCP oficial) | Postgres apenas em dev/test — nunca em produção | não |
| render | `render-useful-mcp` (servidor MCP com `RENDER_API_KEY`) | deploy, logs, serviços | não |
| r2 | `s3-mcp-server` apontando para o endpoint R2 (`AWS_ENDPOINT_URL=https://<account>.r2.cloudflarestorage.com`) | listar/upload/delete em buckets | não |
| resend | MCP remoto `https://mcp.resend.com` (`RESEND_API_KEY`) | envio/teste de e-mail | não |

## Hooks

- `git config core.hooksPath .githooks` ativa o pre-commit (rubocop nos arquivos staged + bloqueio de secrets).
- `.claude/settings.json` bloqueia comandos git destrutivos para agentes (guardrails).
