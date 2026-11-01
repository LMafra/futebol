# Qualidade e ferramentas

Gems e configurações que mantêm o código do Futebol correto, seguro e dentro das fronteiras dos engines. Comandos de CI, segurança e deploy: [OPERATIONS.md](OPERATIONS.md). Índice geral: [docs/README.md](README.md).

Gate local (o `test` de [`.cursor/environment.json`](../.cursor/environment.json)):

```bash
bundle exec rspec && bundle exec rubocop && bundle exec packwerk check && bin/rails zeitwerk:check
```

## Gems de qualidade e segurança

| Gem | Grupo | Função |
|---|---|---|
| `rspec-rails` + `factory_bot_rails` | development, test | suíte de specs e factories |
| `capybara` + `cuprite` | test | system specs em Chrome headless via CDP |
| `prosopite` + `pg_query` | development, test | detecção de N+1; a spec falha |
| `database_consistency` | development, test | divergências schema × models (NOT NULL, unique, FK, `dependent`) |
| `strong_migrations` | development | bloqueia migrations perigosas enquanto são escritas |
| `brakeman` | development, test | análise estática de segurança |
| `bundler-audit` | development, test | CVEs conhecidos nas gems do `Gemfile.lock` |
| `packwerk` | development | fronteiras entre o app e os engines |
| `rubocop-rails-omakase` | development, test | traz o RuboCop (regras em `.rubocop.yml`) |
| `lookbook` | development | previews dos componentes |
| `letter_opener` | development | e-mails abrem no navegador |

## Configuração do RSpec

- `.rspec` carrega `spec_helper`; [`spec/rails_helper.rb`](../spec/rails_helper.rb) sobe o ambiente `test`, aborta em production, mantém o schema de teste (`maintain_test_schema!`), usa fixtures transacionais (`use_transactional_fixtures`) e carrega tudo de `spec/support/` em ordem alfabética.
- [`spec/spec_helper.rb`](../spec/spec_helper.rb): `verify_partial_doubles` e chain clauses nas mensagens de matchers customizados.
- [`spec/support/`](../spec/support):

| Arquivo | O que configura |
|---|---|
| `authentication_helpers.rb` | `sign_in(user)` nas request specs (`POST /session`) |
| `cache.rb` | `Rails.cache.clear` antes de cada exemplo |
| `factory_bot.rb` | sintaxe curta do FactoryBot (`create`, `build`) |
| `opentelemetry.rb` | exporters em memória de spans e log records (test não exporta) |
| `prosopite.rb` | falha em N+1 por request, job e render de componente |
| `pundit.rb` | matchers do Pundit e o shared example `an admin-only policy` |
| `system.rb` | driver Cuprite, `BROWSER_PATH`, `HEADFUL` e screenshots de falha |
| `tailwind_build.rb` | compila o CSS (app + ActiveAdmin) antes da suíte se faltar |
| `view_component.rb` | helpers de ViewComponent e o shared example `a ui component with four states` |

- O CI roda `bundle exec rspec` sem `spec/system` e as system specs num step próprio (ver [OPERATIONS.md](OPERATIONS.md#ci)).

## Ferramentas de qualidade

- **N+1 (`prosopite` + `pg_query`, dev/test):** um N+1 faz a spec falhar com `Prosopite::NPlusOneQueriesError`. A varredura é feita por unidade de trabalho: cada request (middleware Rack em `config/environments/test.rb`, o mais externo depois do `Rack::Events` do OpenTelemetry), cada `perform` de job e cada `render_inline` de componente. Não é feita no exemplo inteiro, porque repetir uma unidade (dois requests, job rodado duas vezes) não é N+1. Configuração: [`spec/support/prosopite.rb`](../spec/support/prosopite.rb); prova: `spec/lib/n_plus_one_detection_spec.rb`.
- **Migrations (`strong_migrations`, development):** bloqueia operações perigosas (`remove_column`, índice sem `algorithm: :concurrently`, etc.) a partir da migration `20261031000031`; as versões aqui são sequenciais.
- **Schema × models (`database_consistency`, dev/test):** `bundle exec database_consistency -c config/database_consistency.todo.yml`. O todo lista os 19 achados existentes (índices redundantes, unique sem validação, `dependent` ausente); o CI falha só em achados novos. Para regenerar: `bundle exec database_consistency -g` grava `.database_consistency.todo.yml` na raiz (caminho fixo da gem); mova o arquivo para `config/`.
- **Componentes (`lookbook`, development):** [`/lookbook`](http://localhost:3000/lookbook), com os previews de `spec/components/previews` (4 estados por componente de `Ui::`).
- **System specs (Capybara + Cuprite, test):** `spec/system/admin_finalizes_match_spec.rb` (admin loga, simula o placar no preview, confirma na finalização e o job pontua) e `spec/system/user_places_bet_spec.rb` (login, entra no bolão pelo código, vê o countdown andar e palpita). Rodam em Chrome headless via CDP, sem chromedriver. Sem Chrome no PATH, defina `BROWSER_PATH` (ex.: o Chromium do Playwright em `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`); sem navegador, as specs ficam pendentes fora do CI. `HEADFUL=1` abre a janela.
- **E-mail (`letter_opener`, development):** e-mails abrem no navegador em vez de sair; as cópias ficam em `tmp/letter_opener`.

### strong_migrations

[`config/initializers/strong_migrations.rb`](../config/initializers/strong_migrations.rb): `start_after` na última versão sequencial antes da gem (`20261031000030`), `target_version` 18 (Postgres 18), `lock_timeout` de 10 s, `statement_timeout` de 1 h e `auto_analyze`. Só carrega em development: checa a migration enquanto ela é escrita, não quando o deploy a roda.

### Brakeman e bundler-audit

- **Brakeman:** `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` (CI `lint` e `bin/ci`). Qualquer warning falha o build; não há `config/brakeman.ignore`.
- **bundler-audit:** `bundle exec bundler-audit check --update` (CI `lint`; `bin/bundler-audit` no `bin/ci`). CVEs que não se aplicam vão na lista `ignore` de [`config/bundler-audit.yml`](../config/bundler-audit.yml), que só o `bin/bundler-audit` lê (hoje só com o placeholder `CVE-THAT-DOES-NOT-APPLY`).

## Packwerk

- [`packwerk.yml`](../packwerk.yml) inspeciona `**/*.{rb,rake,erb}`, exceto `bin`, `node_modules`, `script`, `tmp`, `vendor` e `engines/*/bin`, com cache em `tmp/cache/packwerk`.
- Pacotes com `enforce_dependencies: true`: a raiz ([`package.yml`](../package.yml), o app host) pode usar os 4 engines; `bolao`, `cartola` e `simulador` dependem só de `engines/core`; `core` não depende de nenhum ([ADR 0001](adr/0001-arch.md) §1).
- `bundle exec packwerk validate` confere a configuração dos `package.yml` (ciclos, caminhos); `bundle exec packwerk check` falha em referência a constante fora das dependências declaradas. As duas rodam no job `lint` do CI.

## Padrões de código (RuboCop)

[`.rubocop.yml`](../.rubocop.yml) usa o RuboCop padrão (o `rubocop-rails-omakase` está no Gemfile, mas não é herdado), com `TargetRubyVersion: 3.3` e `NewCops: enable`:

- aspas simples (`Style/StringLiterals`), linhas de até 120 colunas, sem exigir comentário de documentação nem `frozen_string_literal`;
- `Metrics/BlockLength` não vale para specs, rotas, `config/environments` e `app/admin`; `Metrics/MethodLength` e `AbcSize` não valem para migrations;
- `Naming/PredicateMethod` aceita `call` e `save`;
- fora da análise: `bin/`, `db/schema.rb`, `node_modules/`, `tmp/`, `vendor/` e os dummies dos engines.

O pre-commit (`.githooks`) roda o RuboCop nos arquivos Ruby staged; o CI roda em tudo (`bundle exec rubocop --format github`).
