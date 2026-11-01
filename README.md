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

## Ferramentas de qualidade

- **N+1 (`prosopite` + `pg_query`, dev/test):** um N+1 faz a spec falhar com `Prosopite::NPlusOneQueriesError`. A varredura é feita por unidade de trabalho: cada request (middleware Rack em `config/environments/test.rb`, o mais externo depois do `Rack::Events` do OpenTelemetry), cada `perform` de job e cada `render_inline` de componente. Não é feita no exemplo inteiro, porque repetir uma unidade (dois requests, job rodado duas vezes) não é N+1. Configuração: [`spec/support/prosopite.rb`](spec/support/prosopite.rb); prova: `spec/lib/n_plus_one_detection_spec.rb`.
- **Migrations (`strong_migrations`, development):** bloqueia operações perigosas (`remove_column`, índice sem `algorithm: :concurrently`, etc.) a partir da migration `20261031000031`; as versões aqui são sequenciais.
- **Schema × models (`database_consistency`, dev/test):** `bundle exec database_consistency -c config/database_consistency.todo.yml`. O todo lista os 19 achados existentes (índices redundantes, unique sem validação, `dependent` ausente); o CI falha só em achados novos. Para regenerar: `bundle exec database_consistency -g` grava `.database_consistency.todo.yml` na raiz (caminho fixo da gem); mova o arquivo para `config/`.
- **Componentes (`lookbook`, development):** [`/lookbook`](http://localhost:3000/lookbook), com os previews de `spec/components/previews` (4 estados por componente de `Ui::`).
- **System specs (Capybara + Cuprite, test):** `spec/system/admin_finalizes_match_spec.rb` (admin loga, simula o placar no preview, confirma na finalização e o job pontua) e `spec/system/user_places_bet_spec.rb` (login, entra no bolão pelo código, vê o countdown andar e palpita). Rodam em Chrome headless via CDP, sem chromedriver. Sem Chrome no PATH, defina `BROWSER_PATH` (ex.: o Chromium do Playwright em `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`); sem navegador, as specs ficam pendentes fora do CI. `HEADFUL=1` abre a janela.
- **E-mail (`letter_opener`, development):** e-mails abrem no navegador em vez de sair; as cópias ficam em `tmp/letter_opener`.

## Operações

Setup local, ActiveAdmin, seeds e login demo, filas, CI, segurança, Docker, deploy (Render + Supabase + R2 + Resend), observabilidade e MCPs: [docs/OPERATIONS.md](docs/OPERATIONS.md).
