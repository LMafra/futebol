# TICKET-0030 — Cartola configurável por campeonato

- Deps: TICKET-0007, TICKET-0010, TICKET-0025
- Skill: [W]tdd, migration
- MCP: [supabase] `execute_sql` só leitura (1 campeonato, 0 escalações, 220 jogadores com `cost > 0`, 380 partidas com `-rNN-` no `external_id`)
- Spec: §10 (Cartola)
- Estado anterior: formação obrigatória com 11 jogadores; `Lineup::BUDGET = 100` fixo; `core_players.cost` sem padrão por campeonato; sem carteira, valorização nem ranking; rodada só no `external_id` das seeds
- Absorve o derivado do ADR 0003 "`core_matches.round`" (que o ADR numerava 0028), necessário para somar pontos por rodada

## Decisões
- Limites são **máximos por posição**: escalação válida tem ≥ 1 jogador e, em cada posição, no máximo o limite do campeonato. A formação continua salva, mas só como preset de UI: o campo mostra `min(preset, limite)` vagas por linha
- Posições não foram renomeadas: `core_players.position` segue `GOL/LAT/ZAG/MEI/ATA`; `Core::Player::POSITION_SLOTS` mapeia para `goalkeeper` (GOL), `defender` (LAT, ZAG), `midfielder` (MEI), `forward` (ATA). `cartola_lineup_players.position` guarda a vaga
- Preço do jogador = `Cartola::PlayerValue` atual → `core_players.base_value` → `cartola_base_player_value` do campeonato
- Carteira: compra ao salvar (debita os jogadores novos e credita os retirados, a preço atual), devolve tudo ao desfazer. Cada rodada é uma compra própria; o saldo não é renovado por rodada
- Valorização: `novo = valor atual × (1 + (pontos − média da partida) / 100)`, limitada a ±20% por partida pontuada; parte do valor atual (na 1ª vez, o valor base). Estorno (`RevertMatchPointsService`) desfaz a valorização do mesmo `scoring_token`
- Ranking de pontos: soma dos `PlayerScore` mantidos dos jogadores de cada escalação nas partidas da mesma rodada e campeonato. Ranking de moedas: saldo da carteira

## Paths
- Migrations: `engines/core/db/migrate/20261031000032_add_cartola_settings_to_core_championships.rb`, `…033_replace_cost_with_base_value_on_core_players.rb`, `…034_add_round_to_core_matches.rb`; `engines/cartola/db/migrate/20261031000035_scope_cartola_lineups_by_championship.rb`, `…036_create_cartola_wallets_and_player_values.rb`; `db/schema.rb`
- Core: `engines/core/app/models/core/{championship,player,match}.rb`
- Cartola: `engines/cartola/app/models/cartola/{lineup,lineup_player,wallet,player_value,player_value_history}.rb`, `engines/cartola/app/services/cartola/{wallet_service,rankings_service}.rb`, `engines/cartola/app/jobs/cartola/value_update_job.rb`
- App: `app/controllers/cartola/{lineups,rankings}_controller.rb`, `app/views/cartola/{lineups,rankings}/`, `app/components/cartola/{budget_bar,pitch,player_picker,ranking_table}_component.*`, `app/policies/cartola/{lineup,ranking}_policy.rb`, `config/routes.rb`
- Pontuação: `app/jobs/process_match_points_job.rb` (enfileira `Cartola::ValueUpdateJob`), `app/services/revert_match_points_service.rb`, `app/jobs/process_csv_import_job.rb` (coluna `round` opcional)
- Admin: `app/admin/{championships,players,matches,cartola_rankings}.rb`, `app/views/admin/cartola_rankings/_rankings.html.erb`
- Seeds: `db/seeds/{players,matches,demo}.rb`, `db/seeds.rb`

## Pronto quando
- `core_championships`: `cartola_goalkeeper_limit` 1, `cartola_defender_limit` 2, `cartola_midfielder_limit` 3, `cartola_forward_limit` 3, `cartola_initial_budget` 100, `cartola_base_player_value` 5; checks de não negativos e `defensor + meio + atacante > 0`
- `core_players.base_value` (nulo = padrão do campeonato; migrado de `cost > 0`; `cost` removido); `core_matches.round` (1..38, backfill do `-rNN-`)
- `cartola_lineups.championship_id` (unique `squad_id, championship_id, round`); `cartola_lineup_players.position` (check nas 4 vagas)
- `cartola_wallets` (unique `user_id, championship_id`, `balance >= 0`), `cartola_player_values` (unique `player_id, championship_id`), `cartola_player_value_histories` (unique `player_id, scoring_token`)
- `GET/PATCH/DELETE /lineup` (`?championship_id=`, padrão o campeonato mais recente) com saldo; `GET /cartola/rankings?tab=points|coins`
- Admin: 6 campos no form do campeonato, "Valor base" no jogador, página "Rankings" (menu Cartola) e botão no campeonato

## Teste antes/depois
- Antes: 11 jogadores na formação, até C$ 100 fixos
- Depois: `spec/models/cartola/lineup_spec.rb` (limites, LAT+ZAG como defensores, limites alterados, vagas do preset); `spec/services/cartola/wallet_spec.rb`; `spec/jobs/cartola/value_update_job_spec.rb`; `spec/services/cartola/rankings_service_spec.rb`; `spec/requests/cartola/{lineups,rankings}_spec.rb`; `spec/requests/admin/cartola_settings_spec.rb`; `spec/components/cartola/*`; `spec/jobs/core/importers/process_csv_import_spec.rb` (coluna `round`); `spec/seeds_spec.rb`
- Migrations ensaiadas em development: up, rollback das 5 e up de novo
