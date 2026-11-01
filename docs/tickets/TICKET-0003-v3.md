# TICKET-0003 (v3) — (c) AASM Match + guard order no revert_match!

- Deps: TICKET-0002
- Skill: [W]tdd, [C]surgical-patch
- MCP: —
- Spec: `docs/spec-v3.md` §2, §3 + "Specs de regressão obrigatórias"; ADR 0001 §2
- Substitui: `TICKET-0003-v2.md` (resolve os 4 conflitos de `docs/checkpoints/PHASE-3-v2.yaml`)

## Paths
- `engines/core/app/models/core/match.rb`
- `engines/core/db/migrate/20261031000015_add_reverted_status_to_core_matches.rb`
- `spec/models/core/match_spec.rb`, `spec/factories/core.rb` (factory `:match`)

## Pronto quando
- Eventos start_match!/finish_match!/mark_scored!/revert_match!; estado `reverted` (`scored | finished → reverted`)
- Guard `scores_calculated?` lê o valor em memória; `revert_match!` roda ANTES de zerar `scores_calculated_at`
- Zeragem dentro do model: transition `after` atribui `scores_calculated_at = nil`, `scoring_token = nil`, `reversal_token = uuid`, e o AASM persiste em 1 `save` (sem `update_column` externo)
- Constraints: `matches_status_valid` inclui `reverted`; `matches_scored_has_timestamp` = scored ⇒ timestamp; `matches_timestamp_after_finish` = timestamp só em `finished | scored`
- Spec "reverte com scores_calculated_at presente e zera depois" verde (guard viu o valor presente; status `reverted`; timestamp nil depois)
- Spec "falha o guard se scores_calculated_at for nil" verde (`AASM::InvalidTransition`)

## Teste antes/depois
- Antes: `bundle exec rspec spec/models/core/match_spec.rb` → `NoMethodError revert_match!` / factory `finished` + timestamp viola validação
- Depois: os 2 exemplos de regressão passam
