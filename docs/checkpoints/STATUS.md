# STATUS — orquestração (batch 0→7 + rodada de correção) — 2026-10-31

| Fase | Status | Artefato vigente | Falhas | Avisos |
|---|---|---|---|---|
| 0 Bootstrap | ok (v2) | `.gitignore`, `.githooks/pre-commit`, `.claude/`, `.rubocop.yml` | — | +`*.sqlite3` no `.gitignore` |
| 1 ADR | warning (v3) | `docs/adr/0001-arch.md`, `docs/adr/0002-activeadmin-rails81.md` | — | docs originais ausentes; ADR 0002 proposto (confirmar) |
| 2 Design | ok | `docs/design/0001-direction.md` | — | — |
| 2.5 Critique | ok | `docs/design/0001-critique.md` | — | 1 violação tratada na spec |
| 3 Spec | ok (v3) | `docs/spec-v3.md` | — | 4 conflitos do revert_match! resolvidos no TIER-2 (spec-v2 preservada) |
| 4 Tickets | ok (v3) | `docs/tickets/INDEX.md` (22) | — | 0003-v2 herda conflitos; sobreposições 0015×0010, 0017×0004, 0022×0002 |
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
