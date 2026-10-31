# STATUS — orquestração batch 0→7 (2026-10-31)

| Fase | Status | Artefato | Falhas | Avisos |
|---|---|---|---|---|
| 0 Bootstrap | ok | `.githooks/pre-commit`, `.claude/`, `.rubocop.yml`, `README.md` | — | Husky→hook git; jq ausente; MCPs não configurados |
| 1 ADR | warning | `docs/adr/0001-arch.md`, `GLOSSARY.md` | — | 3 docs + 7 correções ausentes → inferidos do prompt |
| 2 Design | ok | `docs/design/0001-direction.md` | — | sugestão da skill (vermelho/Bebas) descartada |
| 2.5 Critique | ok | `docs/design/0001-critique.md` | — | 1 violação (estados win/loss saturados) → ação na spec |
| 3 Spec | ok | `docs/spec.md` | — | to-spec indisponível; riscos ActiveAdmin×Rails 8.1, Tailwind v4 |
| 4 Tickets | ok | `docs/tickets/INDEX.md` + 13 | — | to-tickets indisponível |
| 5 Scaffold | ok | `engines/*`, `app/*`, 12 migrations | — | neon ausente → docker local :5440; `.gitignore` +1 linha do gerador |
| 6 PR | ok | [PR #1](https://github.com/LMafra/futebol/pull/1) | — | repo privado criado; 4 MCPs manual; sem deploy real |
| 7 Compress | ok | `docs/handoffs/PHASE-7.md` | — | caveman-compress/ultracave não executados |

Nenhuma fase `failed` → nenhum banner "⚠ herdou falha". Fase 1 `warning` propagado como aviso a 3→7.

## MCPs
| MCP | status |
|---|---|
| neon | manual — `psql "$NEON_DEV_DATABASE_URL" -c 'SELECT 1'` |
| render | manual — `curl -fsS -X POST "$RENDER_DEPLOY_HOOK_URL"` |
| r2 | manual — `npx wrangler r2 bucket create futebol-dev && npx wrangler r2 bucket create futebol-prod` |
| resend | manual — `curl https://api.resend.com/emails` (ver `docs/mcp/README.md`) |

## Como ajustar
```
0 → independente
1 ─┐
   ├→ 3 → 4 → 5 → 6 → 7
2 → 2.5 ─┘
```
- Corrigir fase N = reexecutar N + todos os descendentes
  - 1 (docs reais de arquitetura) → 3, 4, 5, 6, 7
  - 2 ou 2.5 → 3, 4, 5, 6, 7
  - 3 → 4, 5, 6, 7 · 4 → 5, 6, 7 · 5 → 6, 7 · 6 → 7
- Gravar como nova versão (`*-v2.md`, `PHASE-N-v2.yaml`), nunca sobrescrever

## Próximo passo
- TICKET-0001 — Rails 8 + 4 engines + packwerk (`docs/tickets/TICKET-0001.md`)
```bash
cd /home/lmafra/projects/futebol && git switch -c ticket/0001-engines-packwerk feat/scaffold-docs-deploy-bootstrap && bundle add packwerk --group development && bundle exec packwerk init
```
