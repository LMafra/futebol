# STATUS — orquestração (batch 0→7 + rodada de correção) — 2026-10-31

| Fase | Status | Artefato vigente | Falhas | Avisos |
|---|---|---|---|---|
| 0 Bootstrap | ok (v2) | `.gitignore`, `.githooks/pre-commit`, `.claude/`, `.rubocop.yml` | — | +`*.sqlite3` no `.gitignore` |
| 1 ADR | warning (v3) | `docs/adr/0001-arch.md`, `docs/adr/0002-activeadmin-rails81.md` | — | docs originais ausentes; ADR 0002 proposto (confirmar) |
| 2 Design | ok | `docs/design/0001-direction.md` | — | — |
| 2.5 Critique | ok | `docs/design/0001-critique.md` | — | 1 violação tratada na spec |
| 3 Spec | **warning (v2)** | `docs/spec-v2.md` | — | 4 conflitos no revert_match! (ver PHASE-3-v2) |
| 4 Tickets | ok (v3) | `docs/tickets/INDEX.md` (22) | — | 0003-v2 herda conflitos; sobreposições 0015×0010, 0017×0004, 0022×0002 |
| 5 Scaffold | ok | `engines/*`, `app/*` | — | lock = Rails 8.1.4 (checkpoint dizia 8.1.2) |
| 6 PR | ok | [PR #1](https://github.com/LMafra/futebol/pull/1) | — | 4 MCPs manual |
| 7 Compress | ok | `docs/handoffs/PHASE-7.md` | — | tabela de tickets desatualizada (13 → 22), não regenerada |

## Tiers
| Tier | Tickets ok | failed | blocked | Status |
|---|---|---|---|---|
| 0 | 3 (0001, 0013, 0020) | 0 | 0 | ok — [TIER-0.yaml](TIER-0.yaml) |
| 1 | 3 (0014, 0002, 0011) | 0 | 0 | ok — [TIER-1.yaml](TIER-1.yaml) |

## Correções aplicadas nesta rodada
| correção | status | artefato | impacto |
|---|---|---|---|
| 1 ADR 6 pontos | ok | `PHASE-1-v2.yaml` ("ADR ok, sem alterações") | nenhum; sem cascata |
| 2 ActiveAdmin × Rails 8.1 | ok | `docs/adr/0002-activeadmin-rails81.md`, `PHASE-1-v3.yaml` | TICKET-0001: `activeadmin 4.0.0.beta23` (Plano A via gem) |
| 3 Spec AASM | warning | `docs/spec-v2.md`, `TICKET-0003-v2.md`, `PHASE-3-v2.yaml`, `PHASE-4-v2.yaml` | texto literal aplicado; premissa e bloco RSpec conflitam com AASM real, check constraint e ADR |
| 4 Tickets +9 | ok | `TICKET-0014..0022.md`, `TICKET-0012-v2.md`, `INDEX.md`, `PHASE-4-v3.yaml` | 22 tickets; 0 ciclos; 1 dep para frente (0012→0014/0015) |
| 5 .gitignore | ok | `.gitignore`, `PHASE-0-v2.yaml` | +2 linhas sqlite |

## Conflitos abertos (Correção 3)
- AASM roda event `before` antes dos guards (`aasm/aasm` README L269-273; `lib/aasm/aasm.rb` `fire_default_callbacks` antes de `may_fire?`)
- `revert_match!` com `scores_calculated_at` presente → viola `matches_scored_has_timestamp`
- bloco RSpec usa `finished → reverted`; ADR define `scored → finished`, sem `reverted`
- factory `status: :finished` + timestamp viola a mesma constraint

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
2. Revisar `docs/spec-v2.md` (parágrafo AASM + regression specs) — bloqueia TICKET-0003
3. ~~TIER-1: TICKET-0002, 0011, 0014~~ — concluídos (auth nativa em Core, schema core + seeds, design system + Lookbook)
4. TIER-2 conforme `docs/tickets/INDEX.md` (base `tier/1`)

```bash
cd /home/lmafra/projects/futebol && bin/setup && git switch -c tier/2 tier/1
```
