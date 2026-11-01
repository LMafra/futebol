# TICKET-0017 — Scoring::Engine (Strategy Pattern)

- Deps: TICKET-0016
- Skill: [W]tdd, [W]codebase-design
- MCP: —
- Spec: §7 (`Scoring::Engine.points_for`)

## Paths
- `app/services/scoring/engine.rb` (substitui stub NotImplementedError)
- `app/services/scoring/strategies/{exact_score,winner_and_goal_diff,winner,draw}.rb`
- `spec/services/scoring/engine_spec.rb`, `spec/services/scoring/strategies/*_spec.rb`

## Pronto quando
- Interface única: `Scoring::Engine.points_for(prediction:, home:, away:, rules: ScoringRule.for(pool))`
- Cada strategy: `applies?(guess, result)`; engine aplica a primeira na ordem de precedência; nenhuma → 0
- Puro (sem I/O além das rules injetadas)

## Teste antes/depois
- Antes: `Scoring::Engine.points_for` → NotImplementedError
- Depois: tabela de casos (2x1/2x1=10, 3x2/2x1=7, 1x0/2x1=5, 1x1/0x0=3, 0x1/2x1=0); rules customizadas alteram resultado
