# ADR 0002 — ActiveAdmin × Rails 8.1

- Status: proposto (confirmar antes do TICKET-0001) · Data: 2026-10-31
- Método: [C]investigate-first; fontes = Gemfile.lock local, rubygems API, GitHub API (releases, CI, issues)

## Estado local (`Gemfile.lock`)
| gem | versão |
|---|---|
| rails | 8.1.4 |
| activeadmin | não instalado |
| ransack | não instalado |
| formtastic | não instalado |
- Asset pipeline do app: propshaft + importmap + tailwindcss-rails 4 (Tailwind v4)

## Compatibilidade (últimos 5 releases)
| versão gem | Rails compatível | fonte | confiança |
|---|---|---|---|
| 4.0.0.beta23 (2026-09-20, pre) | railties >= 7.2; CI rails_81 (lock 8.1.3.1) | rubygems deps + `Gemfile.lock@v4.0.0.beta23` | alta |
| 3.5.2 (2026-07-13) | railties >= 6.1; CI matrix rails_81..rails_61 (lock 8.1.3) | rubygems deps + `ci.yaml@v3.5.2` | alta |
| 3.5.1 (2026-03-24) | railties >= 6.1 | rubygems deps | média |
| 3.5.0 (2026-03-09) | railties >= 6.1 | rubygems deps | média |
| 4.0.0.beta22 (2026-03-07, pre) | railties >= 7.2 | rubygems deps | média |
- Deps 3.5.x: arbre ~> 1.2, formtastic >= 3.1, ransack >= 4.0 · Deps 4.0 beta: arbre ~> 2.0, formtastic >= 6.0, ransack >= 4.0
- `master` CI: rails_81 (default), rails_80, rails_72

## Issues "Rails 8.1" no título
| # | estado | tema |
|---|---|---|
| 8993 | fechada (2026-04) | LazyRouteSet quebra `auto_logout_link_path` com símbolo |
| 8537 | fechada (2024-11) | `active_admin.css` não encontrado (Rails 8.1 alpha + master) |
- Abertas: 0

## Decisão
- **Plano A — linha main/4.x**, consumida via gem publicada `activeadmin 4.0.0.beta23` (não git `main`)
- Plano B (Avo): descartado; Plano C (Rails 8.0.x): descartado
- Fallback: 3.5.2 + `dartsass-rails`/sprockets só para o admin

## Justificativa
- Rails 8.1 já é testado em CI nas duas linhas → Plano C desnecessário
- Gargalo é asset pipeline: 4.x é Tailwind/propshaft nativo, igual ao app; 3.5.x exige Sass/sprockets
- Gem publicada fixa versão reprodutível; git `main` muda sem aviso

## Impacto no TICKET-0001
- Gemfile: `gem 'activeadmin', '4.0.0.beta23'` + `bin/rails g active_admin:install` + validar `active_admin.css` no build Tailwind
