# TICKET-0063 — Tema ActiveAdmin (Tailwind v4 / Placar de Domingo)

- Deps: TICKET-0010, TICKET-0011
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-direction

## Escopo
- Tokens `@theme` em `app/assets/stylesheets/active_admin.css` (`paper`, `pitch`, `cartola`, tipografia)
- `config.site_title = "Craquefy Admin"`
- Content paths do Tailwind AA incluem gestor e components
- Spec `spec/requests/admin/theme_spec.rb`

## Paths
- `app/assets/stylesheets/active_admin.css`
- `tailwind-active_admin.config.js`
- `config/initializers/active_admin.rb`
- `spec/requests/admin/theme_spec.rb`

## Pronto quando
- CSS buildado contém `--color-paper`, `--color-pitch`, `--color-cartola`
- `/admin` 200 com título Craquefy Admin e asset `active_admin-*.css`
- Gate `test` verde

## Teste antes/depois
- Antes: AA sem tokens Placar; título só brand
- Depois: tema carregado; `bin/rails tailwindcss:build` ok
