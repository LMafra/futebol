# TICKET-0003 — (c) AASM Match + fix guard order no revert_match!

- Deps: TICKET-0002
- Skill: [W]tdd, [C]surgical-patch
- MCP: —
- Spec: §3, ADR §2

## Paths
- `engines/core/app/models/core/match.rb`
- `spec/models/core/match_state_spec.rb`

## Pronto quando
- Eventos start_match!/finish_match!/mark_scored!/revert_match!
- `revert_match!`: guard `scores_calculated?` → transition `after` (RevertMatchPointsService + assign nil + reversal_token) → save único
- Nenhum `before` de evento chamando revert (roda antes do guard)

## Teste antes/depois
- Antes: spec "revert reverte pontos antes de zerar" falha (implementação ingênua zera primeiro → guard false → `AASM::InvalidTransition`)
- Depois: spec verde — service recebe `match` com `scores_calculated_at` presente; após evento status=finished, `scores_calculated_at` nil, `reversal_token` uuid; revert em `finished` levanta `AASM::InvalidTransition`
