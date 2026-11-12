# STATUS — orquestração (batch 0→7 + rodada de correção) — 2026-10-31

| Fase | Status | Artefato vigente | Falhas | Avisos |
|---|---|---|---|---|
| 0 Bootstrap | ok (v2) | `.gitignore`, `.githooks/pre-commit`, `.claude/`, `.rubocop.yml` | — | +`*.sqlite3` no `.gitignore` |
| 1 ADR | warning (v3) | `docs/adr/0001-arch.md`, `docs/adr/0002-activeadmin-rails81.md` | — | docs originais ausentes; ADR 0002 proposto (confirmar) |
| 2 Design | ok | `docs/design/0001-direction.md` | — | — |
| 2.5 Critique | ok | `docs/design/0001-critique.md` | — | 1 violação tratada na spec |
| 3 Spec | ok (v3) | `docs/spec-v3.md` | — | 4 conflitos do revert_match! resolvidos no TIER-2 (spec-v2 preservada) |
| 4 Tickets | ok (v4) | `docs/tickets/INDEX.md` (27) | — | 0003-v2 herda conflitos; sobreposições 0015×0010, 0017×0004, 0022×0002; +5 tickets de UI/demo (0023–0027) não implementados |
| 5 Scaffold | ok | `engines/*`, `app/*` | — | lock = Rails 8.1.4 (checkpoint dizia 8.1.2) |
| 6 PR | ok | [PR #1](https://github.com/LMafra/futebol/pull/1) | — | 4 MCPs manual |
| 7 Compress | ok | `docs/handoffs/PHASE-7.md` | — | tabela de tickets desatualizada (13 → 22), não regenerada |

## Tiers
| Tier | Tickets ok | failed | blocked | Status |
|---|---|---|---|---|
| 0 | 3 (0001, 0013, 0020) | 0 | 0 | ok — [TIER-0.yaml](TIER-0.yaml) |
| 1 | 3 (0014, 0002, 0011) | 0 | 0 | ok — [TIER-1.yaml](TIER-1.yaml) · [PR #3](https://github.com/LMafra/futebol/pull/3) |
| 2 | 4 (0003, 0016, 0017, 0022) | 0 | 0 | ok — [TIER-2.yaml](TIER-2.yaml) · [PR #4](https://github.com/LMafra/futebol/pull/4) |
| 3 | 5 (0015, 0019, 0018, 0007, 0004) | 0 | 0 | ok — [TIER-3.yaml](TIER-3.yaml) · [PR #5](https://github.com/LMafra/futebol/pull/5) |
| 4 | 4 (0008, 0009, 0005, 0006) | 0 | 0 | ok — [TIER-4.yaml](TIER-4.yaml) · [PR #6](https://github.com/LMafra/futebol/pull/6) |
| 5 | 1 (0010) | 0 | 0 | ok — [TIER-5.yaml](TIER-5.yaml) · [PR #7](https://github.com/LMafra/futebol/pull/7) |
| 6 | 1 (0021) + 1 partial (0012) | 0 | 0 | partial — deploy Render manual (sem `RENDER_DEPLOY_HOOK_URL`) — [TIER-6.yaml](TIER-6.yaml) · [PR #8](https://github.com/LMafra/futebol/pull/8) |

## Desvios técnicos verificados
Fonte de verdade: `docs/adr/0001-arch.md` (o `0001-arch-v2.md` citado no pedido não existe). Nenhum arquivo em `docs/spec-v2.md`, `docs/adr/*` ou `docs/design/*` foi alterado.

| Desvio | Status | Ação tomada | Evidência |
|---|---|---|---|
| 1 — `re_finish` ausente no AASM | ok — semântica OK (não é bug) | nenhuma alteração de código | re-pontuação a partir de `reverted` termina em `scored`, o mesmo estado final da pontuação normal; coberta por `spec/models/core/match_spec.rb` ("can be scored again after a revert") e `spec/services/core/scoring/revert_spec.rb` ("token antigo após re_finish… a partida segue scored") — 44 examples, 0 failures |
| 2 — check constraint de `scores_calculated_at` | ok — 4 regras já cobertas (não é bug) | nenhuma migration nova | `matches_timestamp_after_finish` (`scores_calculated_at IS NULL OR status IN ('finished','scored')`) já rejeita timestamp em `scheduled`, `live` e `reverted`; sondagem no banco de teste via `update_columns` confirma a tabela abaixo |
| 3 — `render.yaml` com worker starter (pago) | ok — fallback documentado (não é bug) | nenhuma alteração (`render.yaml` e README intactos) | worker `plan: starter` mantido; fallback free em `render.yaml` (linha 3) e `README.md` → "Deploy (Render + Neon)"; Puma em production com `SOLID_QUEUE_IN_PUMA=1` sobe Supervisor, Dispatcher, Worker e Scheduler e `/up` responde 200 |

### Desvio 1 — `re_finish` ausente no AASM
Eventos atuais (`engines/core/app/models/core/match.rb`, AASM 6.0.0, 5 estados: `scheduled live finished scored reverted`):

| evento | de → para | guard | after |
|---|---|---|---|
| `start_match` | scheduled → live | `kickoff_reached?` | — |
| `finish_match` | live → finished | `final_score_present?` | — |
| `mark_scored` | finished, reverted → scored | `scores_pending?` | `stamp_scores` |
| `revert_match` | scored, finished → reverted | `scores_calculated?` | `clear_scores` |

- a) Existe transição `reverted → finished`? Não; `reverted` só sai por `mark_scored` (→ `scored`).
- b) Estado final após re-pontuar a partir de `reverted`? `scored` — `ProcessMatchPointsJob` grava os pontos e chama `match.mark_scored!(scoring_token)` na mesma transação.
- c) Existe spec "reverted → rescore → estado final"? Sim:

```ruby
# spec/models/core/match_spec.rb
it 'can be scored again after a revert' do
  match = create(:match, status: 'scored', scores_calculated_at: 1.hour.ago, scoring_token: SecureRandom.uuid)
  match.revert_match!
  match.mark_scored!(SecureRandom.uuid)
  expect(match.reload).to be_scored
end

# spec/services/core/scoring/revert_spec.rb — score! → revert!(old_token) → score!
it 'não re-reverte: os novos scores continuam kept e a partida segue scored' do
  expect { revert!(old_token) }.not_to(change { Bolao::PredictionScore.kept.count })
  expect(match.reload).to be_scored
end
```

Por que não é bug: o critério de bug do pedido era "estado final = `reverted`" ou "sem spec"; nenhum dos dois ocorre. O pedido assume 4 estados (sem `scored`); aqui `scored` é o estado "finalizada e pontuada" e o `re_finish` já existe como `mark_scored!` a partir de `reverted` (nome usado no próprio `revert_spec`). Um evento `reverted → finished` com guard `:scores_calculated?` deixaria a partida re-pontuada em `finished` com timestamp — estado final diferente do fluxo normal (`scored`) — e quebraria as duas specs acima.

### Desvio 2 — check constraint de `scores_calculated_at`
Migration do TICKET-0003: `engines/core/db/migrate/20261031000015_add_reverted_status_to_core_matches.rb` (substitui a `matches_scored_has_timestamp` original de `20261031000004_create_core_matches.rb`, que era `(status = 'scored') = (scores_calculated_at IS NOT NULL)` e proibia timestamp em `finished`). Constraints vigentes em `db/schema.rb`:
- `matches_scored_has_timestamp`: `status <> 'scored' OR scores_calculated_at IS NOT NULL`
- `matches_timestamp_after_finish`: `scores_calculated_at IS NULL OR status IN ('finished','scored')`

Sondagem no banco de teste (`update_columns` por status, que pula as validações do model):

| status | scores_calculated_at permitido | NULL | NOT NULL |
|---|---|---|---|
| scheduled | só NULL | aceito | rejeitado (`matches_timestamp_after_finish`) |
| live | só NULL | aceito | rejeitado (`matches_timestamp_after_finish`) |
| finished | NULL ou NOT NULL (janela `finish_match!` → `ProcessMatchPointsJob`) | aceito | aceito |
| scored | só NOT NULL | rejeitado (`matches_scored_has_timestamp`) | aceito |
| reverted | só NULL | aceito | rejeitado (`matches_timestamp_after_finish`) |

Por que não é bug: `scheduled` e `live` não aceitam timestamp; as 4 regras pedidas (scheduled/live/reverted NULL, finished livre) já valem, mais `scored ⇒ NOT NULL`. A constraint única `chk_scores_calculated_at_by_status` seria só um renome das duas existentes. O model repete as regras (`validates :scores_calculated_at, presence: true, if: scored` e `absence: true, unless: finished/scored`), coberto em `spec/models/core/match_spec.rb`.

### Desvio 3 — `render.yaml` com worker starter (pago)
- Plano do worker: `futebol-worker` → `plan: starter` (`./bin/jobs`); `futebol-web` → `plan: free`. Decisão registrada em `TIER-6.yaml` ("worker starter com ./bin/jobs … Plano free sem worker: SOLID_QUEUE_IN_PUMA=1"); mantida como opção do usuário.
- Fallback documentado nos dois lugares, sem divergência sobre o padrão:
  - `render.yaml`, linha 3: "Free plan without workers: drop futebol-worker and set SOLID_QUEUE_IN_PUMA=1 on futebol-web."
  - `README.md` → "Deploy (Render + Neon)": "No plano free, sem worker: remova `futebol-worker` e defina `SOLID_QUEUE_IN_PUMA=1` no web."
- O fallback funciona: `config/puma.rb` tem `plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']`. Smoke local em production (`SOLID_QUEUE_IN_PUMA=1 bin/rails server`, Postgres local): log com `Started Supervisor(fork)`, `Started Dispatcher`, `Started Worker` e `Started Scheduler`; os 4 processos registrados em `solid_queue_processes`; `/up` 200.

## Tickets de UI/demo adicionados
Só documentos: nenhum ticket foi implementado e nenhum arquivo de código mudou. O pedido citava 27 tickets atuais e numeração 0029–0033; o INDEX tinha 22 (0001–0022, sem 0023–0028 em nenhuma branch ou no histórico), então os novos foram numerados 0023–0027 com aprovação do usuário, e as deps internas foram remapeadas (0030→0024, 0031→0025, 0033→0027).

| ticket | título | deps | observação |
|---|---|---|---|
| [0023](../tickets/TICKET-0023.md) | Bolão: criar e entrar em pool | 0011, 0014 | **implementado** (branch `ticket/0023-bolao-pools`); `Bolao::PoolPolicy` é compartilhada com o ActiveAdmin, que agora exige admin no `authentication_method` |
| [0024](../tickets/TICKET-0024.md) | Bolão: palpites | 0006, 0023 | **implementado** (branch `ticket/0024-bolao-bets`); palpite = `Bolao::Prediction` (sem model `Bet`); `Ui::PredictionFormComponent` da spec §5 criado; seeds de palpites passados salvam com `context: :backfill` |
| [0025](../tickets/TICKET-0025.md) | Cartola: escalação | 0007, 0011 | **implementado** (branch `ticket/0025-cartola-lineup`); migrations `core_players.cost` + `cartola_lineups.formation`; seeds de jogadores ainda com `cost` 0 (custo editável no admin) |
| [0026](../tickets/TICKET-0026.md) | Simulador: definir escopo (ADR) | — | **implementado** (branch `ticket/0026-simulador-adr`): [ADR 0003](../adr/0003-simulador.md) decide pela classificação "e se" pública e sem persistência; derivados 0028 (`core_matches.round`) e 0029 (Simulador v1); criação do ADR novo autorizada pelo usuário (0001/0002 intactos) |
| [0027](../tickets/TICKET-0027.md) | Seeds de demonstração | 0023, 0024, 0025 | **implementado** (branch `ticket/0027-demo-seeds`): `db/seeds/demo.rb` cria `demo1..5@demo.local`, bolão `DEMO01`, 150 palpites, rodadas 1–4/6 pontuadas, 5 ao vivo e 7–10 deslocadas para o futuro, além da escalação 4-3-3 de `demo1` na rodada 7; só em development/test (senha pública no README); jogadores ganham `cost` C$ 4–13 |

## Correções aplicadas nesta rodada
| correção | status | artefato | impacto |
|---|---|---|---|
| 1 ADR 6 pontos | ok | `PHASE-1-v2.yaml` ("ADR ok, sem alterações") | nenhum; sem cascata |
| 2 ActiveAdmin × Rails 8.1 | ok | `docs/adr/0002-activeadmin-rails81.md`, `PHASE-1-v3.yaml` | TICKET-0001: `activeadmin 4.0.0.beta23` (Plano A via gem) |
| 3 Spec AASM | warning | `docs/spec-v2.md`, `TICKET-0003-v2.md`, `PHASE-3-v2.yaml`, `PHASE-4-v2.yaml` | texto literal aplicado; premissa e bloco RSpec conflitam com AASM real, check constraint e ADR |
| 4 Tickets +9 | ok | `TICKET-0014..0022.md`, `TICKET-0012-v2.md`, `INDEX.md`, `PHASE-4-v3.yaml` | 22 tickets; 0 ciclos; 1 dep para frente (0012→0014/0015) |
| 5 .gitignore | ok | `.gitignore`, `PHASE-0-v2.yaml` | +2 linhas sqlite |

## Conflitos da Correção 3 — resolvidos no TIER-2 (TICKET-0003, `docs/spec-v3.md`)
- ~~AASM roda event `before` antes dos guards~~ → zeragem no transition `after` (depois dos guards, 1 único save)
- ~~`revert_match!` com `scores_calculated_at` presente viola `matches_scored_has_timestamp`~~ → constraint virou scored ⇒ timestamp + nova `matches_timestamp_after_finish`
- ~~bloco RSpec usa `finished → reverted`~~ → estado `reverted` adicionado (diverge do ADR 0001 §2, que é imutável; registrado em spec-v3)
- ~~factory `status: :finished` + timestamp viola a constraint~~ → permitido pela constraint nova

## Como ajustar
```
1 → 3 → 4 → 5 → 6 → 7
2 → 2.5 → 3
4 → 10 → 12
```
- Corrigir N = reexecutar N + descendentes; versionar (`-v2`, `-v3`)
- Resolver conflito AASM = correção local na spec (v3) + TICKET-0003 (v3); sem cascata além disso

## Próximos passos
1. ~~Ler ADR 0002~~ e ~~rodar TICKET-0001~~ — concluídos no TIER-0 (Plano A aplicado)
2. ~~Revisar `docs/spec-v2.md` (parágrafo AASM + regression specs)~~ — resolvido em `docs/spec-v3.md` (TICKET-0003-v3)
3. ~~TIER-1: TICKET-0002, 0011, 0014~~ — concluídos (auth nativa em Core, schema core + seeds, design system + Lookbook)
4. ~~TIER-2: TICKET-0003, 0016, 0017, 0022~~ — concluídos (AASM guard-first, ScoringRule Bolão + Cartola, Scoring::Engine, seeds reais)
5. ~~TIER-3: TICKET-0015, 0019, 0018, 0007, 0004~~ — concluídos (Pundit, rate limit 5/3min, anonimização LGPD, preview Cartola dry-run, ProcessMatchPointsJob idempotente; FK `pool_id` adicionada)
6. ~~TIER-4: TICKET-0008, 0009, 0005, 0006~~ — concluídos (broadcast com `unless_exist`, import CSV em streaming com upsert por `external_id`, revert com discard + AuditLog `ip_address`, preview Bolão com `candidate_home/away`; Active Storage instalado)
7. ~~TIER-5: TICKET-0010~~ — concluído (ActiveAdmin sob `PunditAdapter` com 403 para não-admin; 5 custom pages: preview Bolão com placar candidato, finalizador com confirmação do placar, reversão com motivo obrigatório, testador de regras, histórico de auditoria; jobs de pontuação, reversão e import CSV enfileirados pelo admin)
8. ~~TIER-6: TICKET-0021, 0012~~ — 0021 ok (mission_control-jobs em `/admin/jobs` admin-only, Sentry com DSN via ENV e stub em dev); 0012 partial (CI GitHub Actions verde, `render.yaml` web + worker, R2, Resend, keep-alive documentado; deploy no Render não executado por falta de credencial)
9. Pendências manuais do TIER-6 (README → "Deploy"): Blueprint no Render, secret `RENDER_DEPLOY_HOOK_URL`, cron-job.org em `/up`, buckets R2, e-mail de teste Resend, `SENTRY_DSN` real
10. Merge da cadeia de PRs (tier/1 … tier/6) em `main` para o badge do CI refletir a branch padrão

```bash
cd /home/lmafra/projects/futebol && bin/setup && bin/rails db:prepare   # cria futebol_development_queue
```
- Bancos locais criados antes do TIER-3 têm versões órfãs dos stubs Bolão/Cartola (07..12): rodar `bin/rails db:reset`
- TIER-4 adiciona migrations 25 (Active Storage) e 26 (`error_log`): `bin/rails db:migrate`
- TIER-6: development roda jobs no Solid Queue (`bin/dev` inclui `bin/jobs`)

## Correções e migrações de infra
Uma branch, um commit assinado e um PR por bloco, empilhados: cada PR tem como base a branch do bloco anterior. `docs/adr/*` e as specs não foram alterados.

| bloco | status | artefatos | observações |
|---|---|---|---|
| A — inconsistências factuais (P0) | ok (branch `fix/a-inconsistencias`) | `README.md`, `Gemfile`, `Gemfile.lock`, `engines/*/*.gemspec` | README cita **27** tickets, não os 32 do pedido: o INDEX tem 27 linhas (0001–0027) e o critério do bloco é não contradizer o INDEX; 0028/0029 só existem como derivados no ADR 0003. Link de spec → `docs/spec-v3.md`. `rails ~> 8.1.4` no Gemfile e nas 4 gemspecs (lock já era 8.1.4). ActiveAdmin já estava pinado em `4.0.0.beta23`; README ganhou a nota de risco de beta |
| B — CI e segurança (P1) | ok (branch `fix/b-ci-seguranca`) | `.github/workflows/ci.yml`, `.github/dependabot.yml`, `.gitleaksignore`, `LICENSE`, `SECURITY.md`, `README.md` | lint: `packwerk validate` + `bundler-audit check --update` (0 vulnerabilidades); test: `db:seed` 2× depois do RSpec, comparando a linha de contagens; novo job `secrets` com `gitleaks detect` no histórico inteiro (1 falso positivo, nome de chave no `render.yaml`, ignorado por fingerprint); `deploy` passa a depender de `secrets`. Dependabot semanal (bundler + actions), sem `activeadmin` (beta pinado). Licença MIT: repositório público, sem licença antes |
| C — qualidade e gems (P2) | ok (branch `fix/c-qualidade-gems`) | `Gemfile`, `config/initializers/strong_migrations.rb`, `spec/support/prosopite.rb`, `spec/lib/n_plus_one_detection_spec.rb`, `config/environments/{test,development}.rb`, `.database_consistency.todo.yml`, `ci.yml`, `README.md` | `prosopite` faz specs falharem em N+1, por request, job e render de componente; ligá-lo achou 2 N+1 reais, corrigidos (partida selecionada nas 3 páginas de pontuação do admin sem preload de times; `Bolao::Pool#assign_code` com 1 `exists?` por tentativa, agora 1 query). `strong_migrations` com `start_after` na última versão sequencial (bloqueou um `remove_column` de teste). `lookbook` já existia; boot ok e 16 previews (4 componentes `Ui::` × 4 estados) com 200. `letter_opener` em development. `database_consistency`: 19 achados no baseline e step no CI |
| D — system tests (P3) | ok (branch `fix/d-system-tests`) | `Gemfile` (`capybara`, `cuprite`), `spec/support/system.rb`, `spec/system/admin_finalizes_match_spec.rb`, `spec/system/user_places_bet_spec.rb`, `ci.yml`, `README.md`, `Bolao::ScoringRule.by_pool` | 2 system specs verdes (4 execuções seguidas) e step próprio no CI com `RAILS_SYSTEM_TESTING_SCREENSHOT=failed` e screenshots como artifact. A spec do admin pegou mais um N+1 (regras de pontuação carregadas por bolão no preview e no `ProcessMatchPointsJob`), corrigido com `ScoringRule.by_pool` em 1 query. Sem Chrome local, as system specs ficam pendentes, exceto com `CI` definido |
| E — Sentry → OpenObserve (P1) | ok (branch `fix/e-openobserve`) | `Gemfile` (sem `sentry-*`; `opentelemetry-sdk`, `-exporter-otlp`, `-instrumentation-all`, `-logs-sdk`, `-exporter-otlp-logs`, `-instrumentation-logger`), `config/initializers/{opentelemetry,lograge}.rb`, `lib/observability/error_span_subscriber.rb`, `lib/tasks/observability.rake`, 3 jobs, `spec/support/opentelemetry.rb`, `spec/lib/observability_spec.rb`, `.env.example`, `render.yaml`, `README.md` | Sentry removido (gems, initializer, rake task, specs, env). OTel com `service_name` `futebol`, `use_all` e OTLP/HTTP para `OPENOBSERVE_OTLP_ENDPOINT` com `OPENOBSERVE_AUTH`. **Default `http://localhost:5080/api/default`, não `:5081`:** a 5081 é o OTLP/gRPC do OpenObserve e o exporter Ruby fala só HTTP. Erros: subscriber do `Rails.error` emite span `ERROR` com `exception.type/message/backtrace`; os jobs chamam `Rails.error.report`. Logs: Lograge JSON + bridge Logger → OTel logs (sem sidecar). Verificado no OpenObserve local (Docker): trace de `GET /session/new`, span `exception RuntimeError` com status ERROR e log record do Lograge com o mesmo `trace_id`. OpenObserve MCP não usado |
| F — Neon → Supabase (P1) | ok, com passo manual (branch `fix/f-supabase`) | `config/database.yml`, `config/cache.yml`, `bin/docker-entrypoint`, `.env.example`, `render.yaml`, `README.md`, `docs/mcp/README.md`, `.cursor/mcp.json.example`, `spec/config/env_example_spec.rb` | **manual:** criar o projeto Supabase (MCP do Supabase em `needsAuth`, sem credenciais; o agente não cria). `database.yml` lê `SUPABASE_DATABASE_URL` (fallback `DATABASE_URL`), pool 5, `sslmode: require`; na porta 6543 (transaction pooler, runtime) `prepared_statements` e `advisory_locks` ficam `false`; o entrypoint roda `db:prepare` por `SUPABASE_DIRECT_URL` (session pooler 5432, IPv4). Solid Cache/Queue/Cable em bancos irmãos no mesmo projeto; cache de production com `max_size` de 64 MB (500 MB do free tier). `db:prepare` e seed 2× **ensaiados localmente** (Postgres 18 com SSL + PgBouncer transaction na 6543): 3 bancos irmãos criados, contagens iguais nas 2 cargas, Solid Cache/Queue/Cable ok pelo pooler; contra o Supabase real ficam como passo manual. Neon removido de README, `render.yaml`, `.env.example`, `database.yml` e `docs/mcp`; ficam só os registros históricos (tickets, checkpoints PHASE/TIER, handoffs e linhas anteriores deste STATUS), que descrevem o que foi feito na época |
| G — docs de MCP (P2) | ok (branch `fix/g-mcp-docs`) | `docs/mcp/README.md`, `README.md` (MCPs + "Fluxo de deploy com MCP"), `.cursor/mcp.json.example` | 3 MCPs documentados: **Render** (hospedado `https://mcp.render.com/mcp`; serviços, deploys, logs, métricas, env vars; não cria worker/Blueprint e não faz rollback), **Supabase** (stdio `pipx install supabase-mcp-server`; só transaction pooler, sem session pooling; consultas e gestão, não substitui `SUPABASE_DATABASE_URL`) e **OpenObserve** (opcional, `/api/<org>/mcp`; não usado nem configurado). `mcp.json.example` passa a apontar o Render para o MCP hospedado, com `${env:VAR}`. Nenhum secret commitado: credenciais ficam no dashboard do Cursor e no Render; `.cursor/mcp.json` segue no `.gitignore`; gitleaks limpo. O deploy hook do CI cobre só o `futebol-web`; o deploy do worker ficou documentado como passo via MCP ou Dashboard |

## Reorganização da raiz e README
Uma branch, um commit assinado e um PR por bloco, empilhados (cada PR tem como base o anterior). Gate `test` de `.cursor/environment.json` verde em todos (748 exemplos, 0 falhas; RuboCop, Packwerk e Zeitwerk ok). `docs/adr/*` e as specs não foram alterados. Nenhum conteúdo do README antigo foi apagado: cada linha removida foi conferida contra `docs/OPERATIONS.md`, `docs/QUALITY.md` ou o README novo, e não foi preciso um `docs/MISC.md`.

| bloco | status | artefatos | observações |
|---|---|---|---|
| A — docs da raiz → `docs/` | ok ([#29](https://github.com/LMafra/futebol/pull/29), `reorg/a-docs-raiz`) | `docs/agents.md`, `docs/glossary.md`, `.cursor/rules/agents.mdc`, `docs/checkpoints/{TIER-*,PHASE-1}.yaml`, `docs/handoffs/PHASE-1.md`, `docs/tickets/TICKET-0026.md` | `git mv` sem mudar conteúdo; 11 referências atualizadas, 0 fora de `docs/`. O Cursor só carrega automaticamente um `AGENTS.md` na raiz: a regra `.cursor/rules/agents.mdc` (`alwaysApply`) referencia `@docs/agents.md` e `@docs/glossary.md`. `.claude/` não referenciava o arquivo |
| B — `database_consistency` → `config/` | ok, movido ([#30](https://github.com/LMafra/futebol/pull/30), `reorg/b-database-consistency`) | `config/database_consistency.todo.yml`, `.github/workflows/ci.yml` | A gem aceita qualquer arquivo via `-c/--config`. Com o novo caminho, exit 0; sem o `-c`, exit 1 com os 19 achados. `--generate-todo` grava sempre na raiz (caminho fixo da gem); a regeneração está documentada em `docs/QUALITY.md` |
| C — índice `docs/README.md` | ok ([#31](https://github.com/LMafra/futebol/pull/31), `reorg/c-docs-index`) | `docs/README.md` | Modelo do pedido + ADR 0003. `OPERATIONS.md` e `QUALITY.md` entraram no índice nos blocos que os criam, para nenhum commit ter link quebrado |
| D — `docs/OPERATIONS.md` | ok ([#32](https://github.com/LMafra/futebol/pull/32), `reorg/d-operations`) | `docs/OPERATIONS.md`, comentários em `ci.yml`, `.env.example`, `config/database.yml`, `config/initializers/opentelemetry.rb`, `docs/mcp/README.md` | 120 linhas removidas do README: 117 literais no guia e 3 títulos renomeados. Seções novas só com fatos do código ou deste STATUS: login/logout do admin (`DELETE /session`), comandos úteis, Docker, migração Neon → Supabase, Sentry removido. Comentários "ver README" passam a apontar para o guia |
| E — `docs/QUALITY.md` | ok ([#33](https://github.com/LMafra/futebol/pull/33), `reorg/e-quality`) | `docs/QUALITY.md` | 7 linhas removidas, todas literais no guia. Novas seções: gems, RSpec (`spec/support`), strong_migrations, Brakeman/bundler-audit, Packwerk e RuboCop. Registrado como está: o `rubocop-rails-omakase` está no Gemfile, mas não é herdado |
| F — README Best-README-Template | ok ([#34](https://github.com/LMafra/futebol/pull/34), `reorg/f-readme`) | `README.md`, `docs/assets/logo.svg` | 184 linhas, 13 seções, badge de CI em `actions/workflows/ci.yml`; 13 badges com HTTP 200; âncoras do sumário conferidas. Não havia logo (`public/icon.svg` é o padrão do Rails): logo novo na paleta do design. Sem screenshot, o bloco foi removido. Simulador descrito como roadmap (0029 pendente) |
| G — consistência | ok ([#35](https://github.com/LMafra/futebol/pull/35), `reorg/g-consistencia`) | `.github/SECURITY.md`, `config/ci.rb`, `bin/rubocop`, `docs/OPERATIONS.md`, `docs/QUALITY.md`, este STATUS | `find . -maxdepth 1 -name "*.md"` → só `README.md`: o `SECURITY.md` foi para `.github/`, que o GitHub também lê para a política de segurança. 0 links quebrados em 8 docs; `ci.yml` e `render.yaml` sem caminhos antigos. `bin/ci` já existia, mas não rodava testes: ganhou Packwerk, Zeitwerk, `database_consistency` e RSpec, e passa ponta a ponta. O `bin/rubocop` forçava `--config .rubocop.yml` e ignorava `db/.rubocop.yml`, falhando em `db/queue_schema.rb` (o CI e o pre-commit usam `bundle exec rubocop`); o `--config` forçado saiu |

## Deploy Render + Supabase

Workspace Render `tea-cspqio56l47c739ns4ug` (o único da conta). Organização Supabase `vercel_icfg_nHFSDYJMtBIhkEFtOG8I3jmE`. Connection strings e a senha do admin ficam fora do repositório (`~/.config/futebol/supabase.env`, modo 600). Nenhum secret neste arquivo.

| bloco | status | ferramenta MCP | fallback | observações |
|---|---|---|---|---|
| A — provisionar Supabase | ok | `pause_project`, `create_project`, `confirm_cost`, `get_project`, `get_project_url`, `execute_sql`, `list_extensions` | senha: `create_project` não devolve `db_pass`; senha gerada e aplicada com `PATCH /v1/projects/{ref}/database/password` (Management API) | Supabase provisionado: `vopkagghssgdjmkhisrk`. Região `sa-east-1`. API `https://vopkagghssgdjmkhisrk.supabase.co`. `ACTIVE_HEALTHY`; `SELECT 1` ok. `pgcrypto` 1.3 e `plpgsql` 1.0 instalados. `income-expenses` (`algniphsdcrcquvlxjfu`) pausado para liberar o free tier; `supabase-citrine-arrow` segue ativo. Custo confirmado: US$ 0/mês. Pooler real é `aws-1-sa-east-1.pooler.supabase.com` (o host `aws-0` responde `tenant/user not found`). Session 5432 e transaction 6543 aceitam a role `postgres`. Migrations ainda não rodaram. |
| B — conferir a app | ok, sem alteração de código | nenhuma (config já no `main`) | — | `config/database.yml`, `.env.example` e `render.yaml` ficam como estão. Runtime: transaction pooler **6543** (`prepared_statements` e `advisory_locks` false). Migrations: session pooler **5432** (statements ligados), via `SUPABASE_DIRECT_URL` no `bin/docker-entrypoint`. Bancos irmãos `postgres_cache`, `postgres_queue`, `postgres_cable`. O template com `DATABASE_URL` única e `prepared_statements: false` fixo não foi aplicado: quebraria `spec/config/env_example_spec.rb`. Neon já não está no blueprint. `db:prepare` continua no entrypoint, não no build. Gate: 748 examples, 0 failures, 2 pending. |
| C — migrations | ok | `execute_sql`, `list_tables` | — | `db:prepare` pela session 5432 criou `postgres_cache`, `postgres_queue` e `postgres_cable` (`rolcreatedb` true). `schema_migrations` = 24, igual aos arquivos em `db/migrate` e `engines/*/db/migrate`. Tabelas do app: `core_matches`, `core_users`, `bolao_pools`, `cartola_lineups`. Queue tem `solid_queue_jobs` (15 tabelas); cache tem `solid_cache_entries`; cable tem `solid_cable_messages`. `db:seed` uma vez com `ALLOW_PRODUCTION_SEED=1`: 20 times, 220 jogadores, 380 partidas, 1 admin. `core_users` com `email_address LIKE '%@demo.local'` = 0 (senha demo não vai para production). RLS do schema `public` está desligado: o app usa a role `postgres` (não a API anon). Não habilitei RLS sem política, porque isso é decisão à parte e bloquearia a API do Supabase. |
| D — serviço Render | ok | `create_web_service` | — | Serviço `futebol-web`, id `srv-dbjlfmk9v7es73aeuikg`, URL `https://futebol-web.onrender.com`, dashboard `https://dashboard.render.com/web/srv-dbjlfmk9v7es73aeuikg`. Docker, plano free, região Ohio, branch `main`, `autoDeploy` no. `HTTP_PORT=10000`, `RAILS_ENV=production`, `SOLID_QUEUE_IN_PUMA=1`, `RAILS_LOG_LEVEL=info`. Sem worker. A criação disparou o deploy `dep-dbjlfn49v7es73aeuk3g` antes das env vars secretas; o deploy com segredos fica no bloco F. `db:prepare` está no `bin/docker-entrypoint`, não num `buildCommand` (runtime Docker). |
| E — env vars | ok | — | env vars: via Render API (`PUT /v1/services/{id}/env-vars`), não pelo MCP | O MCP `update_environment_variables` existe, mas os valores iriam para o transcript. A API fez merge e não imprimiu segredo. Conferido só por nome e forma: `SUPABASE_DATABASE_URL` na porta 6543, `SUPABASE_DIRECT_URL` na 5432, `RAILS_MASTER_KEY` presente, e as quatro variáveis públicas do bloco D preservadas. Sem `OPENOBSERVE_*`, `R2_*` ou `RESEND_*` (não há instância hospedada; upload e e-mail ficam manuais). |
| F — deploy | ok, `live` | `trigger_deploy`, `list_deploys`, `list_logs` | — | Deploy limpo `dep-dbjlhbg473hc73a73cog` (`clearCache: true`) ficou `live`. O deploy da criação (`dep-dbjlfn49v7es73aeuk3g`) terminou `update_failed` antes desse. `GET /up` → 200 em 0,29 s (instância já ligada; não esperei os 15 min de hibernação). `GET /` → 302 para `/session/new`. `core_users` segue 1 admin e 0 `@demo.local`. Log de runtime: um erro do AWS SDK tentando o metadata service `169.254.169.254` porque `R2_*` não está definido; o boot e o `/up` não dependem disso. |
| G — documentação | ok | — | push dos PRs: bloqueado pelo hook local (`git push`) | `docs/OPERATIONS.md` e `docs/mcp/README.md` ganharam a URL, o ref, o `serviceId`, o pooler `aws-1`, os comandos MCP e o fallback de cada um. Sem segredos. Os commits A–G estão assinados nas branches `deploy/a-supabase` … `deploy/g-docs`, empilhadas. O hook do ambiente bloqueou `git push`, então os PRs não foram abertos daqui. |

## Lacunas de produto resolvidas

Um ticket, uma branch e um commit assinado por bloco, empilhados a partir de `deploy/g-docs`. Gate `test` de `.cursor/environment.json` (RSpec, RuboCop, Packwerk, Zeitwerk) verde depois de cada bloco, sem nenhuma falha repetida; nenhum bloco ficou `blocked`. ADRs 0001, 0002 e 0003 não foram alterados; o ADR 0004 é novo, a pedido. MCP Supabase usado só para leitura (`execute_sql`); MCP Render usado só para acompanhar deploys e logs: nenhum bloco precisa de env var nova. Os PRs foram empilhados ([#36](https://github.com/LMafra/futebol/pull/36) docs do deploy → #37 → #40) e entraram na `main` por merge commit; o restack do GitHub reescreveu os commits, por isso os hashes da `main` diferem dos originais.

| bloco | status | ticket | branch · commit | gate | observações |
|---|---|---|---|---|---|
| A — signup público | ok | [0028](../tickets/TICKET-0028.md) | [#37](https://github.com/LMafra/futebol/pull/37) · `d565500` | 764 ex., 0 falhas | `/signup` com `Ui::SignupFormComponent`, rate limit 5/3 min, `name` obrigatório só na criação; e-mails `@invalid` (contas anonimizadas) recusados |
| B — Bolão 2 faixas | ok | [0029](../tickets/TICKET-0029.md) | [#38](https://github.com/LMafra/futebol/pull/38) · `67f71be` + `1482f5d` | 760 ex., 0 falhas | [ADR 0004](../adr/0004-bolao-scoring.md). Produção antes da migração: 4 linhas globais 10/7/5/3 e 0 bolões → vira 1 global 10/5 (`winner_and_goal_diff` 7 e `draw` 3 passam a valer `winner_points`) |
| C — Cartola por campeonato | ok | [0030](../tickets/TICKET-0030.md) | [#39](https://github.com/LMafra/futebol/pull/39) · `48be641` + `ceb6f0e` | 812 ex., 0 falhas | Produção antes da migração: 1 campeonato, 0 escalações, 220 jogadores com `cost > 0` (viram `base_value`), 380 partidas com `-rNN-` (viram `round`) |
| D — Simulador v1 | ok | [0031](../tickets/TICKET-0031.md) | [#40](https://github.com/LMafra/futebol/pull/40) · `95e6929` | 831 ex., 0 falhas | Escopo do ADR 0003 seguido; rotas do ticket e do ADR coexistem |

Os commits `1482f5d` (B) e `ceb6f0e` (C) corrigem o CI dos PRs: `database_consistency` (exceções no todo para `belongs_to` de models do core, que o Packwerk impede de ganhar `has_many`; checks e validações de presença no histórico de valores; índice redundante `index_core_matches_on_championship_id` removido na 034) e Brakeman (`public_send` com `params[:tab]` no `RankingsController`). As migrations 034 e 036 foram ajustadas antes de rodar em produção.

Deploy:

- O primeiro deploy (`dep-dbjnj57f3r2c73ckg2jg`, commit `2dd98d0`) falhou na 031 com `undefined method 'safety_assured'`: o `strong_migrations` estava só no grupo `development`, e o Dockerfile instala com `BUNDLE_WITHOUT="development"`. O CI não pegou porque o banco de teste carrega o `schema.rb` em vez de rodar as migrations. A transação da 031 foi desfeita (produção ficou na 030) e o deploy anterior continuou no ar.
- [#42](https://github.com/LMafra/futebol/pull/42) (`fix/strong-migrations-producao`): a gem foi para o grupo padrão, e o CI ganhou o passo "Recent migrations, production bundle", que desce até `StrongMigrations.start_after` e sobe de novo com `BUNDLE_WITHOUT=development`, depois do seed.
- Deploy `dep-dbjnvbnb9u1s73buhsb0` (commit `69bb65e`, disparado pelo commit novo na `main`) `live` em 2026-11-01 18:09 UTC. Supabase (só leitura) confirma `20261031000031`…`036` aplicadas:
  - 1 regra global do Bolão com 10/5, sem `kind`/`points`;
  - `core_players.cost` removido, 220 jogadores com `base_value`;
  - 380/380 partidas com `round`;
  - 0 escalações, carteiras e valores.
- Smoke test em produção: `/up`, `/signup`, `/simulador` e `/session/new` → 200; `/cartola/rankings` → 302 (login).
- O único erro nos logs depois do deploy (`Error retrieving instance profile credentials`, SDK da AWS no boot) já aparecia no deploy anterior.
- O `futebol-web` agora tem `autoDeploy: yes` com gatilho `commit` (antes era manual): cada commit na `main` vira deploy, sem esperar o CI. O job `Deploy (Render)` do CI segue sem efeito, porque `RENDER_DEPLOY_HOOK_URL` não está configurado e o job só emite um aviso.

Os 2 exemplos `pending` são os system specs que precisam do Chrome.

### Decisões e desvios registrados
- **Numeração do ADR 0003.** O ADR chama de 0028 o `core_matches.round` e de 0029 o Simulador v1. O pedido reservou 0028–0031 para signup, Bolão, Cartola e Simulador. O `core_matches.round` entrou no TICKET-0030, que precisa dele para o ranking por rodada, e o Simulador é o TICKET-0031. O ADR não foi editado.
- **Posições do jogador (condição de parada).** `core_players.position` já era `GOL/LAT/ZAG/MEI/ATA` (string com check, não enum), diferente de `goalkeeper/defender/midfielder/forward`. Não renomeei: `Core::Player::POSITION_SLOTS` mapeia GOL → `goalkeeper`, LAT e ZAG → `defender`, MEI → `midfielder`, ATA → `forward`, e `cartola_lineup_players.position` guarda a vaga.
- **Limites do Cartola são máximos.** A escalação precisa de ≥ 1 jogador e de no máximo o limite em cada posição. A formação virou preset de UI: o campo mostra `min(preset, limite)` vagas. Com os padrões (1/2/3/3), nenhum preset cabe inteiro, por isso a formação não restringe nada. Escalações antigas acima dos novos limites continuam gravadas; só ao editar precisam se ajustar (produção tem 0).
- **Carteira.** Debita os jogadores novos e credita os retirados a preço atual; desfazer devolve tudo. Cada rodada é uma compra própria, e o saldo não é renovado entre rodadas: com C$ 100 e jogadores de C$ 4–13, o usuário escala poucas rodadas sem desfazer as anteriores. Renovar o saldo por rodada (ou carregar o time entre rodadas) fica para um ticket próprio.
- **Valorização.** O pedido usa `base_value × (1 + (score − média)/100)`. Implementado sobre o **valor atual** (igual ao base na primeira vez), para a valorização acumular, com teto de ±20% por partida pontuada. A média é a dos `Cartola::PlayerScore` mantidos da partida. Hoje nenhum código cria `PlayerScore` (só factory e preview), então o job não altera valores em produção até existir a ingestão de scouts. O Reversal desfaz a valorização do mesmo `scoring_token`.
- **Simulador.** O ADR vence onde diverge do pedido: desempate por pontos, **vitórias**, saldo, gols pró e nome (o pedido não citava vitórias); jogos `live` só contam pelo placar do formulário. O service se chama `Simulador::StandingsCalculator`, como no pedido (o ADR dizia `ProjectStandings`). As rotas do pedido (`/simulador/:championship_id`, `/preview`) e as do ADR (`/simulador`, `/simulador/projecao`) apontam para o mesmo controller. Os atalhos opcionais "empate em branco" e "mandante vence" ficaram fora da v1.

## Infra de produção configurada

Uma branch e um commit assinado (SSH) por bloco, empilhados a partir de `docs/status-deploy-lacunas` (já na `main` pelo PR #43). O push ficou com o usuário, porque o hook do ambiente bloqueia `git push` pelo agente: `git push -u origin infra/a-openobserve infra/b-r2 infra/c-resend infra/d-keep-alive infra/e-docs`. Gate `test` de `.cursor/environment.json` verde depois de cada bloco: 832 exemplos, 0 falhas, 2 pending (system specs sem Chrome); RuboCop, Packwerk e Zeitwerk ok. ADRs 0001–0004 e specs não foram alterados. Nenhum secret commitado.

| bloco | status | branch · commit | artefatos | observações |
|---|---|---|---|---|
| A — OpenObserve self-hosted | ok | `infra/a-openobserve` · `ffb52a6` | `docker/openobserve/docker-compose.yml`, `config/initializers/opentelemetry.rb`, `spec/config/env_example_spec.rb`, `spec/lib/observability_spec.rb`, `.env.example`, `render.yaml`, `.gitignore`, `.dockerignore`, README, OPERATIONS, `docs/mcp` | Não havia endpoint fixo do Cloud: `OPENOBSERVE_OTLP_ENDPOINT`/`OPENOBSERVE_AUTH` viraram `OTEL_EXPORTER_OTLP_ENDPOINT`/`OTEL_EXPORTER_OTLP_HEADERS`. **O endpoint é a URL base** (`http://localhost:5080/api/default`), e o app acrescenta `/v1/traces` e `/v1/logs`. O valor do pedido (`.../v1/traces`) mandaria os logs para `.../v1/traces/v1/logs`; a semântica padrão foi aprovada pelo usuário. O fallback por ambiente foi mantido (development usa localhost, production só exporta com a variável, test nunca exporta), em vez de `ENV.fetch` com localhost em todos os ambientes. Bug evitado: um `OTEL_EXPORTER_OTLP_HEADERS=` vazio (o `.env` padrão) derrubava a configuração do SDK, então vazio vira `{}`. O compose subiu localmente (`/healthz` 200), e um trace (`exception RuntimeError`, `ERROR`) e um log record chegaram ao stream `default` com o header novo |
| B — Cloudflare R2 | ok, com passo manual | `infra/b-r2` · `254472b` | README, OPERATIONS, `docs/mcp/README.md` | Prompt oficial (`developers.cloudflare.com/agent-setup/prompt.md`) executado: para o Cursor, ele pede as skills e o MCP `mcp.cloudflare.com/mcp`, que o plugin da Cloudflare já instala; o MCP foi autenticado (OAuth). O CLI `cf`, opcional, não foi instalado. De início a API devolvia `10042 Please enable R2 through the Cloudflare Dashboard`. Depois que o usuário habilitou o R2 no Dashboard, os buckets `futebol-dev` e `futebol-prod` foram criados pelo MCP (ENAM, Standard). O token S3 (`R2_ACCESS_KEY_ID`/`R2_SECRET_ACCESS_KEY`) fica manual, para o secret não passar pelo agente. `storage.yml` já apontava para o R2 (`R2_ACCOUNT_ID`/`R2_ENDPOINT`, `R2_BUCKET_DEV`/`R2_BUCKET_PROD`, mantidos em vez de um `R2_BUCKET` único) |
| C — Resend | ok, com passo manual | `infra/c-resend` · `fa49c10` | `.env.example`, README, OPERATIONS | O SMTP já estava em `production.rb` (`smtp.resend.com:465`, `tls: true`, equivalente a `ssl: true` no Mail). Não existe `config/initializers/mailer.rb` nem a gem `resend`, então não há conflito. `RESEND_API_KEY` não existe no Render: placeholder `re_xxxxxxxxx` documentado. Manual: conta, API key, domínio verificado (SPF/DKIM) e `RESEND_*` no `futebol-web` |
| D — keep-alive | ok | `infra/d-keep-alive` · `7389e59` | `.github/workflows/keep-alive.yml`, README, OPERATIONS | Não havia workflow de keep-alive. O novo roda `*/14 * * * *` + `workflow_dispatch`, com `permissions: {}`, secret via `env:`, retry e `--max-time 90` para o cold start; sem o secret, só avisa. Secret `RENDER_APP_HOST` = `futebol-web.onrender.com` cadastrado com `gh secret set` (o exemplo do pedido dizia `futebol.onrender.com`, que não é o host real). Ping local com o mesmo `curl`: 200. O `schedule` só vale depois do merge na `main`; o cron-job.org, ajustado para `*/14`, fica como alternativa |
| E — documentação | ok | `infra/e-docs` · `56acc1e` + `d9535bb` + revisão final | README (seção "Infraestrutura de produção" com OpenObserve, R2, Resend e keep-alive, além do roadmap; auto-deploy por commit corrigido), `docs/README.md` (links da infra), OPERATIONS ("Estado deste deploy", comandos úteis, status dos MCPs), `docs/mcp`, este STATUS | Sem referência ao OpenObserve Cloud nem a `OPENOBSERVE_*` fora dos registros históricos. Neon só aparece na seção de migração de OPERATIONS e no ADR 0003, que é imutável |

Secrets a configurar:

| Secret | Onde | Estado |
|---|---|---|
| `RENDER_APP_HOST` | GitHub Actions | cadastrado (`futebol-web.onrender.com`) |
| `RESEND_API_KEY`, `RESEND_FROM` | Render (`futebol-web`) | chave válida (validada no `.env` local: login SMTP ok e envio para `delivered@resend.dev` aceito; permissão só de envio). Pendente: domínio verificado (hoje o remetente é `onboarding@resend.dev`) e as variáveis no Render, que não deu para conferir pelo MCP |
| `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | Render (`futebol-web`) | pendente: buckets criados, falta o token S3 |
| `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS` | Render (`futebol-web`) | pendente (host do OpenObserve) |
| `ZO_ROOT_USER_EMAIL`, `ZO_ROOT_USER_PASSWORD` | host do OpenObserve | padrão do compose só para uso local; senha forte no VPS |

Validar o OpenObserve local: `docker compose -f docker/openobserve/docker-compose.yml up -d` e depois `curl localhost:5080/healthz`.

## Entrega de home, login, rename e rebranding

Onze blocos, cada um numa branch `craquefy/<bloco>` empilhada a partir da `main`, com um commit assinado (SSH). O gate `test` de `.cursor/environment.json` (RSpec, RuboCop, Packwerk e Zeitwerk) passou depois de cada bloco, sem falha repetida, e nenhum bloco ficou `blocked`. No último gate: 926 exemplos, 0 falhas e 2 pending (system specs sem Chrome). O push fica com o usuário, porque o ambiente bloqueia `git push` pelo agente:

```bash
git push -u origin craquefy/a-private-flag craquefy/b-esquadrao craquefy/b2-locale craquefy/c-login craquefy/c2-consent craquefy/d0-scouts craquefy/d1-captain-valuation craquefy/d-rankings craquefy/e-home craquefy/f-brand craquefy/g-docs
```

| bloco | status | ticket | branch · commit | observações |
|---|---|---|---|---|
| A — flag privado | ok | [0032](../tickets/TICKET-0032.md) | `craquefy/a-private-flag` · `7966a2b` | Migration 037 com índice concorrente; privado some da home, da página pública e do Simulador para visitantes (404 por id) |
| B — Esquadrão | ok | [0034](../tickets/TICKET-0034.md) | `craquefy/b-esquadrao` · `ee50cfc` | Só texto e URLs; 301 de `/cartola`, `/cartola/rankings` e das URLs antigas do admin, com a query string |
| B2 — pt-BR | ok | [0037](../tickets/TICKET-0037.md) | `craquefy/b2-locale` · `64a0d1f` | Gem nova `rails-i18n`: quem baixar a branch roda `bundle install` |
| C — login | ok | [0033](../tickets/TICKET-0033.md) | `craquefy/c-login` · `950ec4c` | O broadcast do placar mandava o layout inteiro no turbo-stream; passou a `layout: false` |
| C2 — consentimento | ok | [0038](../tickets/TICKET-0038.md) | `craquefy/c2-consent` · `88cafab` | Usuários antigos ficam anônimos ("Participante") até consentirem |
| D0 — scouts | ok | [0039](../tickets/TICKET-0039.md) | `craquefy/d0-scouts` · `b332b83` | Placar derivado dos scouts; finalização bloqueada sem scouts |
| D1 — capitão e valorização | ok | [0040](../tickets/TICKET-0040.md) | `craquefy/d1-captain-valuation` · `db217dc` | [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md) novo; cenário B da dica dá C$ 18.69, não 18.44 |
| D — rankings públicos | ok | [0035](../tickets/TICKET-0035.md) | `craquefy/d-rankings` · `dea20c7` | Bolão conta a maior pontuação por partida entre os bolões do usuário |
| E — home pública | ok | [0032](../tickets/TICKET-0032.md) | `craquefy/e-home` · `0fd8e6a` | Sem as referências do Mobbin (abaixo) |
| F — Craquefy | ok | [0036](../tickets/TICKET-0036.md) | `craquefy/f-brand` · `7209ead` | `site_title` do admin como proc, avaliado por request |
| G — docs | ok | — | `craquefy/g-docs` | Tickets 0032–0040, INDEX com 40, README e este STATUS |

### Desvios e pendências
- **Mobbin indisponível.** A busca respondeu "requires a paid plan", então não houve referências de FotMob, Sofascore, Onefootball, Sleeper ou Cartola FC. A hierarquia da home seguiu o design system: faixa-placar sem cards, módulos em 8/4 e "Entrar" como único acento laranja.
- **Oferta e demanda na valorização** fica pendente, sem ticket numerado (também registrado no ADR 0005). A valorização atual é só regressão à média por jogador.
- **Migrations novas** (037–042): `core_championships.private`, `core_users.public_profile_consented_at`, scouts em `cartola_player_scores`, colunas da regra do Esquadrão, `cartola_lineup_players.captain` e colunas de `cartola_player_value_histories`. O plano registrou 0 linhas nas tabelas de scouts, escalações e histórico de valores em produção.
- **Nada foi renomeado** em engines, packages, tabelas `cartola_*`, models, services, classes, rotas internas ou repositório. ADRs 0001–0004, `docs/spec-v2.md` e `docs/design/*` não foram alterados.

### N+1 evitados
- Rankings do Bolão e do Esquadrão de todos os campeonatos em 2 queries agrupadas e uma carga de usuários (`Core::ChampionshipRankingsService.top`).
- Times e status por campeonato em 2 queries agrupadas na home.
- Top 10 de atletas numa query agrupada com `preload(player: :team)`.
- Jogos de hoje com `includes(:home_team, :away_team)`.
- Tela de scouts com jogadores em `includes(:team)` e PlayerScores indexados por jogador.
- O Prosopite falha os request specs ao detectar N+1; home, campeonato e scouts passam.

### Validação
Local (`bin/rails s -p 3005`, banco de development com o seed):

| URL | resultado |
|---|---|
| `/` | 200; `<title>Craquefy</title>`, meta description da marca, 0 e-mails e 0 "Futebol" no HTML |
| `/entrar` | 200 |
| `/campeonatos/1`, `?tab=bolao`, `?tab=esquadrao` | 200 |
| `/campeonatos/999999` | 404 |
| `/admin`, `/esquadrao`, `/minha-conta` | 302 → `/session/new` |
| `/cartola?x=1` | 301 → `/esquadrao?x=1` |
| `/simulador` | 200 |

Produção (`futebol-web`, deploy `dep-dbjpha7avr4c73cbpqtg`, antes do merge destas branches). As primeiras chamadas deram 502 enquanto o Puma subia depois da hibernação (`connection refused` no proxy até "Listening on 0.0.0.0:3000"). Depois do boot: `/up` 200, `/` 302 → `/session/new`, `/entrar` 404, `/campeonatos/1` 404, `/esquadrao` 404, `/cartola/rankings` 302, `/admin` 302 e `/simulador` 200. Depois do merge, o esperado é `/` 200, `/entrar` 200, `/campeonatos/1` 200 e `/cartola/rankings` 301.

```bash
for url in /up / /entrar /campeonatos/1 /esquadrao /cartola/rankings /admin /simulador; do
  printf "%-20s %s\n" "$url" "$(curl -s -o /dev/null --max-time 90 -w '%{http_code} %{redirect_url}' "https://futebol-web.onrender.com$url")"
done
```

### Ajustes pós-entrega (TICKET-0041)
Branch `craquefy/h-ajustes`, empilhada sobre `craquefy/g-docs`, com um commit assinado; entra no mesmo push das outras 11 branches.
- `/simulador` virou a lista de campeonatos para escolher (privados só para quem está logado); o simulador abre em `/simulador/:id`, sem login, e a página do campeonato ganhou o botão "Simular". Diverge do ADR 0003, que descrevia `GET /simulador` abrindo o simulador direto; o ADR não foi editado.
- Jogos em aberto em carrossel: uma rodada por vez, com "Anterior" e "Próxima". As rodadas ocultas continuam no formulário, e sem JS ficam empilhadas.
- Rodapé: "Desenvolvido por LMafra" (GitHub) e "Pague o Café" com a chave Pix e botão de copiar. A chave Pix é um e-mail publicado de propósito; as specs de privacidade checam os e-mails dos usuários, não qualquer `@` na página.

### Jogos de hoje com vários campeonatos (TICKET-0042)
Branch `craquefy/i-campeonatos-seed`, empilhada sobre `craquefy/h-ajustes`, com três commits assinados (o segundo mistura públicos e privados; o terceiro tira dos textos a visibilidade e deixa os contadores gerais).
- Fora do admin, nenhum texto diz se o campeonato é público ou privado. Os contadores da home contam todos os campeonatos e partidas; as listas continuam só com os públicos.
- "Jogos de hoje" agrupa por campeonato, com o nome (link) e a contagem de jogos de cada um.
- Seed local com 5 campeonatos fictícios de 6, 8, 10, 12 e 6 times, em turno único, com a rodada do meio hoje: 3 públicos e 2 privados (Liga Amadora Carioca e Liga Sulista Sub-20), que a home não mostra. Só em development/test, como a demo: as datas acompanham o dia em que o seed roda, o que não faz sentido em produção.
- Os 42 times novos não têm elenco, porque o seletor do Esquadrão lista todos os jogadores do banco. Filtrar o seletor pelos times do campeonato fica como melhoria futura.

### Simulador pelos cards e rolagem guiada (TICKET-0043)
Branch `craquefy/j-simulador-cards`, empilhada sobre `craquefy/i-campeonatos-seed`, com um commit assinado.
- O link "Simulador" saiu do cabeçalho; cada card de campeonato da home tem "Simular".
- O carrossel do simulador traz todas as rodadas: abre na primeira com jogo em aberto, e "Anterior" mostra os resultados das encerradas, sem campos.
- A home tem scroll snap obrigatório (seções, cabeçalho e rodapé). O Turbo mantém os atributos do `<html>` entre visitas, então um controller Stimulus liga e desliga o snap; verificado no navegador que o simulador e a volta para a home ficam corretos.
- O app rodava em UTC (`config.time_zone` não definido), então "Jogos de hoje" virava o dia às 21h de Brasília. Resolvido no TICKET-0045.

### Tabela projetada no lugar da atual (TICKET-0044)
Branch `craquefy/k-simulador-tabela`, empilhada sobre `craquefy/j-simulador-cards`, com um commit assinado.
- O Turbo Frame do simulador envolve a tabela e as rodadas: ao projetar, a tabela projetada substitui a atual no mesmo lugar.
- "Zerar simulação" aparece depois de projetar e recarrega o frame no estado inicial. Verificado no navegador (projetar e zerar na Copa da Várzea Paulista).

### Fuso em Brasília (TICKET-0045)
Branch `craquefy/l-fuso-brasilia`, empilhada sobre `craquefy/k-simulador-tabela`, com um commit assinado.
- `config.time_zone = 'Brasilia'`: "hoje", horários exibidos e datas do CSV seguem Brasília; o banco continua em UTC.
- Em produção, partidas importadas por CSV antes desta mudança (lidas como UTC) ficariam 3 horas antes do pretendido; as do seed já usavam o fuso de São Paulo.

### Scroll snap por proximidade (TICKET-0046)
Branch `craquefy/m-snap-proximity`, empilhada sobre `craquefy/l-fuso-brasilia`, com um commit assinado.
- O snap da home passou de obrigatório para proximidade (`snap-proximity`): só encaixa quando a rolagem para perto do início de uma seção.

### Classificação no card de campeonato (TICKET-0047)
Branch `craquefy/n-card-classificacao`, empilhada sobre `craquefy/m-snap-proximity`, com um commit assinado.
- Cada card da home abre com as 4 primeiras posições da tabela real (só partidas encerradas) e o link "Tabela completa"; o Top 3 do Bolão e o do Esquadrão vêm depois. Verificado no navegador com os 4 campeonatos públicos do seed.

### Jogos de hoje em faixa horizontal (TICKET-0048)
Branch `craquefy/o-jogos-hoje-carrossel`, empilhada sobre `craquefy/n-card-classificacao`, com um commit assinado.
- "Jogos de hoje" deixou de agrupar por campeonato (TICKET-0042): é uma faixa só, por horário, com o campeonato dentro de cada card, para a seção não crescer com o número de campeonatos.
- Botões de anterior e próximo no cabeçalho da seção, que só aparecem quando a faixa transborda. Verificado no navegador com os 14 jogos públicos do seed.

### Jogos de hoje sem fim (TICKET-0049)
Branch `craquefy/p-jogos-hoje-loop`, empilhada sobre `craquefy/o-jogos-hoje-carrossel`, com um commit assinado.
- A faixa dá a volta: cópias dos cards (`aria-hidden`, fora do Tab) antes e depois dos originais, e um salto de uma volta inteira quando a rolagem assenta numa cópia. Verificado no navegador nos dois sentidos.
- A barra de rolagem horizontal continua visível e fica no meio durante a volta; esconder a barra precisaria de CSS fora das utilidades do design system. Resolvido no TICKET-0050.

### Jogos de hoje sem barra de rolagem (TICKET-0050)
Branch `craquefy/q-sem-barra`, empilhada sobre `craquefy/p-jogos-hoje-loop`, com um commit assinado.
- Nova utilidade `scrollbar-none` no CSS do Tailwind, usada na faixa de "Jogos de hoje". A faixa continua rolando pelas setas, toque, trackpad e shift + roda. Verificado no navegador.

### Jogos de hoje com cards inteiros (TICKET-0051)
Branch `craquefy/r-jogos-hoje-passo`, empilhada sobre `craquefy/q-sem-barra`, com um commit assinado.
- Cards em frações exatas da faixa (1, 2, 3 ou 4 por tela), sem o último cortado; as setas andam um card por clique. Verificado no navegador.
- No celular cabe um card inteiro por vez, sem a ponta do próximo; o total de jogos e as setas indicam que há mais.

### Scouts no seed demo (TICKET-0052)
Branch `craquefy/s-seed-scouts`, empilhada sobre `craquefy/r-jogos-hoje-passo`, com um commit assinado.
- O seed lança os scouts das 50 partidas finalizadas do Brasileirão (1.100 linhas), com gols batendo o placar, e o "Ranking de atletas" da home mostra 10 jogadores. Verificado no navegador, já com o seed rodado no banco local.
- Os campeonatos pequenos continuam sem scouts, porque os times deles não têm elenco.

### Esquadrão só com jogadores do campeonato (TICKET-0053)
Branch `craquefy/t-esquadrao-elenco`, empilhada sobre `craquefy/s-seed-scouts`, com um commit assinado.
- O seletor da escalação lista só os jogadores dos times com partida no campeonato, mais os já escalados; o salvamento ignora jogador de fora. Preparação para dar elenco aos times dos campeonatos pequenos (TICKET-0054).

### Top 3 Bolão e Esquadrão no seed dos campeonatos (TICKET-0054)
Branch `craquefy/u-seed-rankings`, empilhada sobre `craquefy/t-esquadrao-elenco`, com um commit assinado.
- Os 5 campeonatos pequenos ganham elencos, bolão, palpites, scouts, pontuação e escalações dos usuários demo; no Brasileirão, `demo2`–`demo5` escalam na rodada 6. Todos os cards da home mostram Top 3 Bolão e Top 3 Esquadrão. Verificado no navegador, com o seed rodado no banco local.
- `demo1`–`demo3` autorizam o perfil público (Ana S., Bruno L., Carla M.); os outros aparecem como "Participante".
- Uma carga do zero leva cerca de 8 s no spec (o job de pontuação roda por partida encerrada); a segunda carga não cria nada.

### "Como funciona" logo depois dos módulos (TICKET-0055)
Branch `craquefy/v-como-funciona`, empilhada sobre `craquefy/u-seed-rankings`, com um commit assinado.
- A home passa a ter "Como funciona" entre "Três jeitos de jogar" e "Jogos de hoje". Verificado no navegador.

## RBAC: 3 níveis

Trabalho concentrado na branch única `cursor/rbac-i-pendencias-9a4f`, recriando os blocos A–H+I que estavam em branches `rbac/*` locais e nunca foram enviadas ao remoto. Um push assinado cobre enums, pedido de gestor, policies com escopo, namespace `/gestor`, painel, pontuação pelo gestor e comentários no admin.

### Blocos

| bloco | status | ticket | observações |
|---|---|---|---|
| A — papéis e `manager_id` | ok | [0056](../tickets/TICKET-0056.md) | Migrations 043–046 no engine `core`; enums com `prefix` |
| B — pedido de gestor | ok | [0057](../tickets/TICKET-0057.md) | `/gestor/solicitar`, mailer, aprovação no admin (Usuários) |
| C — policies com escopo | ok | [0058](../tickets/TICKET-0058.md) | `ApplicationPolicy#Scope`, `Gestor::*` espelhando `Core::*` |
| D — namespace `/gestor` | ok | [0059](../tickets/TICKET-0059.md) | `Gestor::PunditAdapter`, recursos em `app/admin/gestor/` |
| E — logins por área | ok | [0059](../tickets/TICKET-0059.md) | `/admin/login`, `/gestor/login`, redirect por papel |
| F — painel e premiação | ok | [0060](../tickets/TICKET-0060.md) | Migration 047; `Gestor::ChampionshipOverview`; classes `panel` / `data-table` |
| G — scouts, finalizar, reverter | ok | [0061](../tickets/TICKET-0061.md) | Páginas Pontuação em `:admin` e `:gestor`; atalhos no painel |
| H — docs e README | ok | [0056](../tickets/TICKET-0056.md)–[0062](../tickets/TICKET-0062.md) | Tickets 0056–0062, INDEX (62), glossário, esta seção |
| I — comentários ActiveAdmin | ok | [0062](../tickets/TICKET-0062.md) | Migration 048; `comments = true` no admin; 404 em `/gestor/comments` |

### Matriz de permissões (resumo)

| Recurso / ação | Admin (`/admin`) | Gestor (`/gestor`, campeonatos próprios) | Usuário |
|---|---|---|---|
| Plataforma (import CSV, auditoria, usuários, preview Bolão) | sim | não (403 no `/admin`) | não |
| Campeonatos (CRUD) | todos | criar; editar/ver os com `manager_id` dele | não |
| Times e jogadores | todos | criar; editar times só nos próprios campeonatos | não |
| Partidas (CRUD agendadas) | todos | criar/editar agendadas nos próprios campeonatos | não |
| Partidas — **scouts** | sim | sim, nos próprios campeonatos | não |
| Partidas — **finalizar** | sim | sim, nos próprios campeonatos | não |
| Partidas — **reverter** | sim | sim, nos próprios campeonatos | não |
| Regras do Bolão do campeonato | sim | sim, nos próprios | não |
| Bolões e escalações (admin) | sim | só leitura nos próprios | não |
| Comentários nos recursos | sim | não (`403` em `/admin/comments`; `/gestor/comments` → 404) | não |
| Bolão / Esquadrão (app) | como usuário | como usuário | sim |
| Pedir ser gestor | — | — | `/gestor/solicitar` |

### Desvios

- Tickets documentados como **0056–0062**, não 0037–0041 (numeração antiga do plano).
- Namespace ActiveAdmin **`:gestor`**, não um controller Rails separado.
- Enums `role` e `manager_status` com **`prefix`** para evitar colisão com `admin` e `none`.
- Migrations de domínio no engine **`core`** (043–047); `active_admin_comments` no host (`db/migrate/048`).
- Comentários do ActiveAdmin **habilitados** com tabela própria; desligados só no namespace gestor.
- Painel do gestor usa as mesmas classes visuais das telas de pontuação do admin (`panel`, `panel-title`, `data-table`).
- `curl` contra HTML deve enviar **`Accept: text/html`**; sem isso o Rails pode responder `406` em rotas que negam JSON.

### Validação

Local (`bin/rails s -p 3005`, seed com `gestor@demo.local` / `demo-futebol`; conferido no Playwright):

| URL | esperado |
|---|---|
| `/gestor/login` | 200, campo `area=gestor` |
| `/admin/login` | 200, campo `area=admin` |
| `/gestor` sem sessão | 302 → login |
| `/gestor` como gestor | 200, atalhos Scouts/Finalizar/Reverter |
| `/gestor/matchscouts` e `/gestor/matchfinalizer` | 200 para o gestor |
| `/admin/championships/:id` | painel de comentários (`active_admin_comments_for`) |
| `/admin` como gestor | 403 |
| `/gestor/matchscouts?match_id=…` (partida alheia) | 403 |

Produção (`https://futebol-web.onrender.com`, depois do deploy da branch na `main`):

```bash
HOST=https://futebol-web.onrender.com
HDR='Accept: text/html'

for url in /up /entrar /admin/login /gestor/login /gestor /admin /; do
  printf "%-18s " "$url"
  curl -sS -o /dev/null --max-time 90 -H "$HDR" -w '%{http_code} %{redirect_url}\n' "$HOST$url"
done
```

Esperado após o merge RBAC: `/up` 200; `/entrar`, `/admin/login` e `/gestor/login` 200; `/gestor` e `/admin` anônimos 302 para o login correspondente ou `/session/new`; gestor autenticado acessa `/gestor` e leva 403 em `/admin`.

**Nota:** scouts, finalizar e reverter no `/gestor` **já estão disponíveis** para o gestor nos próprios campeonatos (bloco G / TICKET-0061); não ficam mais como pendência do STATUS.

## UI unificada de admin e gestor (Placar de Domingo)

Tickets **0063–0067** (os números 0042–0046 do plano original já estavam ocupados). `docs/design/*` não foi alterado (regra agents); a decisão de aplicar o tema ao ActiveAdmin fica aqui e nos tickets.

| Bloco | Ticket | Status | Artefatos |
|---|---|---|---|
| A — tema Tailwind v4 | [0063](../tickets/TICKET-0063.md) | ok | `@theme` em `active_admin.css`; `site_title = Craquefy Admin`; `theme_spec` |
| B — chrome | [0064](../tickets/TICKET-0064.md) | ok | `_site_header` / `_main_navigation` / `_site_footer`; layout paper; sem dark FOUC |
| C — tabelas | [0065](../tickets/TICKET-0065.md) | ok | `.data-table` pitch/zebra; `Ui::AdminTableComponent` |
| D — forms | [0065](../tickets/TICKET-0065.md) | ok | Formtastic Placar + `AdminHelper` cartola |
| E — dashboards | [0066](../tickets/TICKET-0066.md) | ok | métricas 8/4 admin; cards 3/9 gestor |
| F — status/ranking | [0067](../tickets/TICKET-0067.md) | ok | `StatusBadgeComponent`; medalhas SVG no leaderboard |
| G — docs | — | ok | INDEX, STATUS, README |
| polish | — | ok | labels pt-BR; panel/header/flash/blank slate; filters; attributes; logged-out; pagination pitch; comments |
| publish | — | blocked | hook do ambiente bloqueia publicação remota; integração com 7 commits A–G; bundle em artifacts |
| Mobbin | — | n/a | MCP Mobbin exige plano pago; estrutura 8/4 e 3/9 já aplicada via design docs |

## UI/UX de admin e gestor (status-first)

Tickets **0068–0073** (0047–0052 do plano UX já estavam ocupados). Sem alteração em engines/models/ADRs `0001–0004` nem em `docs/design/*`.

| Bloco | Ticket | Status | Artefatos | Observações |
|---|---|---|---|---|
| A — layout | [0068](../tickets/TICKET-0068.md) | ok | `_site_sidebar`; `layout_spec` | paper/rule |
| B — nav | [0069](../tickets/TICKET-0069.md) | ok | menus por tarefa + SVG | tip `0bc6668` |
| C — dashboards | [0070](../tickets/TICKET-0070.md) | ok | KPIs 8/4 + SVG; cards gestor | tip `89b74ef` (+ KPI SVG fix no tip) |
| D — tabelas | [0071](../tickets/TICKET-0071.md) | ok | filter bar + ações SVG | tip `d2437c8` |
| E — forms | [0072](../tickets/TICKET-0072.md) | ok | seções + Toast + Turbo Stream | tip `ab7d231` |
| F — empty/mobile | [0073](../tickets/TICKET-0073.md) | ok | EmptyState; sidebar `< md` | tip `23be79d` |
| G — docs | — | ok | INDEX, STATUS, README | este bloco |
| publish | — | blocked | push do agente bloqueado pelo hook; bundles em `/opt/cursor/artifacts/admin-ux-*.bundle` | tip UX empilha A–F |
| Mobbin | — | n/a | MCP pago; tokens via design docs | — |

Branches (1 commit assinado por bloco):

| Bloco | Branch | Tip |
|---|---|---|
| A+B | `cursor/admin-ux-nav-e3a0` (layout+nav) | `0bc6668` |
| C | `cursor/admin-ux-dashboards-e3a0` | `89b74ef` |
| D | `cursor/admin-ux-tables-e3a0` | `d2437c8` |
| E | `cursor/admin-ux-forms-e3a0` | `ab7d231` |
| F | `cursor/admin-ux-feedback-e3a0` | `23be79d` |
| G | `cursor/admin-ux-docs-e3a0` | `c9e2d92` (+ `8d2492b` KPI SVG) |

Gate `.cursor/environment.json` `test`: 1076 examples, 0 failures (após Bloco F).

## UI/UX work queue (pós-Gemini / IHC)

Tickets **0074–0078**. Chrome unificado; 1º viewport especializado (Admin = governança/exceções; Gestor = ownership/fila de partidas). Sem alteração em engines/models/ADRs `0001–0005` nem em `docs/design/*`.

| Bloco | Ticket | Status | Artefatos | Observações |
|---|---|---|---|---|
| H1 — limpar CTAs | [0074](../tickets/TICKET-0074.md) | planned | — | remove Ações rápidas / Atalhos |
| H2 — fila Admin | [0075](../tickets/TICKET-0075.md) | planned | — | Aprovar inline; rejeitar com justificativa |
| H3 — fila Gestor | [0076](../tickets/TICKET-0076.md) | planned | — | 1 CTA por status; Reverter no overflow |
| H4 — wizard new | [0077](../tickets/TICKET-0077.md) | planned | — | staged disclosure só no create |
| H5 — Red Routes | [0078](../tickets/TICKET-0078.md) | planned | — | SEQ + clicks nos 3 cenários |
| G — docs H | — | ok (local) | INDEX, STATUS, README; tip `ec1aa89` | branch `cursor/admin-work-queue-docs-e3a0`; push bloqueado — bundle `/opt/cursor/artifacts/admin-work-queue-docs.bundle` |

Diagnóstico: tip status-first ainda trata setup e operação com o mesmo peso (button soup). Alvo: work queue + progressive disclosure.

Checklist anti-AI (`0001-critique`): sem gradiente roxo, glass, Inter/Roboto só, emoji decorativo, glow; badges estáticos; Fraunces ≥ `text-xl`; `loss` como tint + texto ink.

Validação local (após login):

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' http://127.0.0.1:3000/admin
curl -sS -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' http://127.0.0.1:3000/gestor
```

Produção (`https://futebol-web.onrender.com`):

```bash
HOST=https://futebol-web.onrender.com
HDR='Accept: text/html'
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' -H "$HDR" "$HOST/admin"
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' -H "$HDR" "$HOST/gestor"
```

