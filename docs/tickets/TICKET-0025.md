# TICKET-0025 — Cartola: escalação

- Deps: TICKET-0011, TICKET-0007
- Skill: implement-spec (indisponível localmente → [W]tdd), [C]migration
- MCP: [neon] dev para `db:migrate` (opcional; fallback local)
- Spec: §2 (Cartola `squads`, `lineups`), §5 (4 estados), §7 (`Cartola::CalculatePreviewService`)
- Estado atual: `Cartola::Lineup` (`squad_id`, `round` 1..38) e `Cartola::LineupPlayer` já existem (TICKET-0007) — estender, não recriar; `core_players` não tem `cost`

## Paths
- `engines/core/db/migrate/*_add_cost_to_core_players.rb` (`cost numeric(5,2) not null default 0`, check `cost >= 0`)
- `engines/cartola/db/migrate/*_add_formation_to_cartola_lineups.rb` (`formation string not null`, check `formation IN (...)`)
- `engines/cartola/app/models/cartola/{lineup,lineup_player}.rb`, `engines/core/app/models/core/player.rb`
- `app/controllers/cartola/lineups_controller.rb`, `config/routes.rb` (`resource :lineup, only: %i[show edit update]`, param `round`)
- `app/policies/cartola/lineup_policy.rb`
- `app/components/cartola/{formation_picker,pitch,player_picker,budget_bar}_component.{rb,html.erb}`
- `spec/requests/cartola/lineups_spec.rb`, `spec/models/cartola/lineup_spec.rb`, `spec/policies/cartola/lineup_policy_spec.rb`

## Pronto quando
- `Lineup::FORMATIONS = %w[3-4-3 3-5-2 4-3-3 4-4-2 4-5-1 5-3-2 5-4-1]`; a formação define quantos `ZAG+LAT`, `MEI` e `ATA` + 1 `GOL`
- Validações: exatamente 11 jogadores; contagem por posição bate com a formação; soma de `Player#cost` ≤ `Lineup::BUDGET` (100); jogador repetido proibido (unique já existe)
- `LineupsController` usa o `Cartola::Squad` do `Current.user` (cria no 1º acesso); `update` substitui os `lineup_players` numa transação
- LineupPolicy: dono do squad lê/edita; outro usuário → 403; admin só lê
- `BudgetBar` mostra gasto/restante (`tabular-nums`); `Pitch` posiciona por formação; `PlayerPicker` filtra por posição; todos com 4 estados + previews

## Teste antes/depois
- Antes: escalação só existe via factory; sem formação, sem custo, sem limite de orçamento
- Depois:
  - request spec com 10 exemplos: show da própria escalação; show sem squad cria squad; edit renderiza formação + orçamento; update válido (11, formação, ≤100) salva; update com 10 jogadores → 422; com 12 → 422; formação inválida → 422; acima de 100 → 422; escalação de outro usuário → 403; sem sessão → redirect `/session/new`
  - model spec com 6 validações: 11 jogadores ok; ≠11 inválido; formação fora da lista inválida; posições incompatíveis com a formação inválidas; orçamento = 100 ok; orçamento > 100 inválido
  - policy spec com 3: dono `update?` true; outro usuário `update?` false; admin `show?` true e `update?` false
