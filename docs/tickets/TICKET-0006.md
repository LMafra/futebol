# TICKET-0006 — (f) Preview Bolão (candidate_home/away)

- Deps: TICKET-0004
- Skill: [W]tdd
- MCP: —
- Spec: §7

## Paths
- `engines/bolao/app/services/bolao/calculate_preview_service.rb`
- `spec/services/bolao/calculate_preview_service_spec.rb`

## Pronto quando
- `call(match:, candidate_home:, candidate_away:)` → `Preview = Data.define(:rows, :total)`
- Reusa `Scoring::Engine`; zero writes (sem insert/update)
- Valida candidatos inteiros ≥0 (ArgumentError)

## Teste antes/depois
- Antes: service inexistente / usa placar real da partida
- Depois: com candidate 2x1 e palpite 2x1 → 10 pts; `expect { call }.not_to change(PredictionScore, :count)`; candidate negativo → ArgumentError
