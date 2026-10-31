# Handoff — Fase 0 (Bootstrap) — ok

## Decisões
- Repo: `/home/lmafra/projects/futebol`, branch `main`
- Pre-commit: hook git nativo `.githooks/pre-commit` (rubocop staged + bloqueio de secrets), ativo via `core.hooksPath`
- Guardrails: `.claude/hooks/block-dangerous-git.sh` (push, reset --hard, clean -f, branch -D, checkout/restore .)
- `.gitignore` Rails 8 + engines; `.rubocop.yml` mínimo (single quotes, 120 col)

## Paths
- `README.md` (seção MCPs: 4 linhas, todos "não")
- `.rubocop.yml`, `.gitignore`, `.githooks/pre-commit`, `.claude/settings.json`

## Avisos
- Husky substituído por hook git (sem npm/gems)
- MCPs ausentes: neon, render, r2, resend
- Fase 5 deve rodar `rails new . --skip` para não sobrescrever README/.gitignore/.rubocop.yml
