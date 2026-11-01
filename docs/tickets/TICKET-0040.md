# TICKET-0040 — Capitão e valorização por regressão à média

- Deps: TICKET-0030, TICKET-0039
- Skill: [W]tdd
- MCP: —
- Spec: §9; [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md)
- Estado anterior: sem capitão; valorização de ±20% sobre a média da partida

## Escopo
- Capitão obrigatório e único por escalação (`cartola_lineup_players.captain`, índice único parcial por `lineup_id WHERE captain`): radio "C" no picker, selo em campo; pontos ×2 no ranking, inclusive negativos; capitão que não jogou não tem PlayerScore, logo sem bônus
- `Cartola::Valuation.new_price`: `expected = atual × 0.45 + (atual − inicial) × 0.25 × peso`, com peso 0 no 1º jogo do jogador no campeonato, 0.5 no 2º e no 3º e 1 depois; `variação = clamp((pontos − expected) / 4, −5, +5)`; `novo = max(atual + variação, 0.50)`
- `Cartola::ValueUpdateJob` reprecifica só quem jogou, com os pontos sem a dobra do capitão; mantém a idempotência por `scoring_token` e o `revert!` do Reversal; `cartola_player_value_histories` ganha `expected_score` e `games_played`
- Oferta e demanda fica como pendência, sem ticket (ADR 0005 e STATUS)

## Paths
- `engines/cartola/db/migrate/20261031000041_add_captain_to_cartola_lineup_players.rb`, `20261031000042_add_valuation_columns_to_cartola_player_value_histories.rb`
- `engines/cartola/app/models/cartola/{lineup,player_value_history}.rb`, `engines/cartola/app/services/cartola/{valuation,rankings_service}.rb`, `engines/cartola/app/jobs/cartola/value_update_job.rb`
- `app/components/cartola/{pitch,player_picker}_component.*`, `app/controllers/cartola/lineups_controller.rb`, `app/views/cartola/lineups/edit.html.erb`, `db/seeds/demo.rb`
- `docs/adr/0005-esquadrao-pontuacao-valorizacao.md`

## Pronto quando
- Escalação sem capitão não salva ("Escolha um capitão entre os escalados")
- Cenário A da dica: C$ 5, inicial 5, 8 pontos → C$ 6.44; cenário B (4º jogo): C$ 20, inicial 15, 5 pontos → C$ 18.69 (a dica dizia 18.44)

## Teste antes/depois
- Antes: ranking somava os pontos sem capitão
- Depois: `spec/services/cartola/valuation_spec.rb`, `spec/jobs/cartola/value_update_job_spec.rb`, `spec/models/cartola/lineup_spec.rb`, `spec/services/cartola/rankings_service_spec.rb`, `spec/requests/cartola/{lineups,rankings}_spec.rb`
