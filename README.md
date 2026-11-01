# Futebol

[![CI](https://github.com/LMafra/futebol/actions/workflows/ci.yml/badge.svg)](https://github.com/LMafra/futebol/actions/workflows/ci.yml)

Plataforma Rails 8 com engines `core`, `bolao`, `cartola` e `simulador`.

- Monolito modular Rails 8.1 + Postgres; engines dependem só de `core` ([ADR 0001](docs/adr/0001-arch.md))
- Pontuação idempotente (`scoring_token`) e reversível (`revert_match!` reverte antes de zerar `scores_calculated_at`)
- Design "Placar de Domingo": verde-campo, laranja-cartola, Fraunces + Source Sans 3 ([direção](docs/design/0001-direction.md), [crítica](docs/design/0001-critique.md))
- Escopo e contratos em [spec v3](docs/spec-v3.md); trabalho em 27 tickets ([INDEX](docs/tickets/INDEX.md))
- Admin em ActiveAdmin `4.0.0.beta23`, pinado no Gemfile ([ADR 0002](docs/adr/0002-activeadmin-rails81.md)). É um pré-release: a API pode mudar entre betas, então atualize só de forma deliberada (Gemfile + `bundle update activeadmin` + suíte de `spec/requests/admin`). O fallback estável é a 3.5.x, com Sass/sprockets só para o admin.
- Infra: Render + Supabase (Postgres) + R2 + Resend + OpenObserve ([MCPs](docs/mcp/README.md)); status das fases em [STATUS](docs/checkpoints/STATUS.md)
- Índice da documentação: [docs/README.md](docs/README.md)

## Operações

Setup local, ActiveAdmin, seeds e login demo, filas, CI, segurança, Docker, deploy (Render + Supabase + R2 + Resend), observabilidade e MCPs: [docs/OPERATIONS.md](docs/OPERATIONS.md).

## Qualidade

Gems de qualidade e segurança, RSpec, N+1, migrations, schema, Lookbook, system specs, Packwerk e RuboCop: [docs/QUALITY.md](docs/QUALITY.md).
