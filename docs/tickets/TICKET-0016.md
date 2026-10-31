# TICKET-0016 — ScoringRule model + migration

- Deps: TICKET-0002
- Skill: [W]tdd, [C]migration
- MCP: [neon] dev para `db:migrate` (opcional; fallback local)
- Spec: §7 (regra 10/7/5/3/0)

## Paths
- `engines/bolao/db/migrate/*_create_bolao_scoring_rules.rb`
- `engines/bolao/app/models/bolao/scoring_rule.rb`, `spec/models/bolao/scoring_rule_spec.rb`

## Pronto quando
- Colunas: `pool_id` (null = regra global), `kind` (exact_score, winner_and_goal_diff, winner, draw), `points` int not null
- `add_check_constraint` `points >= 0` e `kind IN (...)`; unique `(pool_id, kind)`
- Seed global idempotente com 10/7/5/3

## Teste antes/depois
- Antes: pontos hardcoded; tabela inexistente
- Depois: `points: -1` → `ActiveRecord::StatementInvalid`; kind duplicado no mesmo pool → `RecordNotUnique`; `ScoringRule.for(pool)` cai na regra global quando pool não tem override
