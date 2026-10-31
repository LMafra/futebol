# TICKET-0013 — (m) MCP setup: docs/mcp/README.md + smoke test

- Deps: TICKET-0001
- Skill: [M]find-skills (fallback), [C]verify-and-stop
- MCP: [neon] [render] [r2] [resend]
- Spec: §9; README seção MCPs

## Paths
- `docs/mcp/README.md`, `.cursor/mcp.json.example` (sem segredos)

## Pronto quando
- Por MCP: instalação, env vars, escopo, smoke test, comando manual equivalente
- Smoke: neon `SELECT 1` (dev) · render `list_services` · r2 `list_buckets` · resend envio p/ endereço de teste
- README raiz atualizado (configurado? sim/não)

## Teste antes/depois
- Antes: README marca 4 MCPs "não"; smoke indisponível
- Depois: 4 smoke tests registrados (ok/manual/falhou) em `docs/mcp/README.md`
