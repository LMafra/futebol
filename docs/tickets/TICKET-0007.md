# TICKET-0007 — (g) Preview Cartola (dry-run Data.define)

- Deps: TICKET-0002
- Skill: [W]tdd
- MCP: —
- Spec: §7

## Paths
- `engines/cartola/app/services/cartola/calculate_preview_service.rb`
- `engines/cartola/db/migrate/*` (squads, lineups, player_scores)
- `spec/services/cartola/calculate_preview_service_spec.rb`

## Pronto quando
- `call(lineup:, stats:)` retorna `Data.define(:player_points, :total)` imutável
- Dry-run: nenhuma escrita em `player_scores`

## Teste antes/depois
- Antes: service inexistente
- Depois: total = soma dos jogadores; `expect { call }.not_to change(Cartola::PlayerScore, :count)`; resultado `frozen?`
