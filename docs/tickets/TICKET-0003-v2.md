# TICKET-0003 (v2) — (c) AASM Match + fix guard order no revert_match!

- Deps: TICKET-0002
- Skill: [W]tdd, [C]surgical-patch
- MCP: —
- Spec: `docs/spec-v2.md` §3 + "Specs de regressão obrigatórias"; ADR 0001 §2
- ⚠ Conflitos abertos: ver `docs/checkpoints/PHASE-3-v2.yaml` (warnings) antes de implementar

## Paths
- `engines/core/app/models/core/match.rb`
- `engines/core/spec/models/core/match_spec.rb`
- `spec/factories/matches.rb` (factory `:match`)

## Pronto quando
- Eventos start_match!/finish_match!/mark_scored!/revert_match!
- Guard `scores_calculated?` lê valor em memória
- Fluxo: (a) `@match.revert_match!` com `scores_calculated_at` presente; (b) `@match.update_column(:scores_calculated_at, nil)`
- Spec "reverte com scores_calculated_at presente e zera depois" verde
- Spec "falha o guard se scores_calculated_at for nil" verde (`AASM::InvalidTransition`)

## Bloqueios conhecidos (resolver antes do verde)
- Spec usa estado `reverted`, transição `finished → reverted`; ADR 0001 §2 define `scored → finished` (sem `reverted`)
- Check constraint `matches_scored_has_timestamp` (spec §2) rejeita `status = finished` com `scores_calculated_at` presente → factory e passo (a) falham no Postgres

## Teste antes/depois
- Antes: `bundle exec rspec engines/core/spec/models/core/match_spec.rb` falha (`Core::Match` sem AASM / factory inexistente)
- Depois: os 2 exemplos de regressão passam
