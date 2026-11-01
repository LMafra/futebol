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
