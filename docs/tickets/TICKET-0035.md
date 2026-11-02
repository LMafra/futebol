# TICKET-0035 — Página pública do campeonato com rankings

- Deps: TICKET-0029, TICKET-0030, TICKET-0032 (flag privado), TICKET-0038, TICKET-0040
- Skill: [W]tdd
- MCP: —
- Spec: §9 e §10; [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md) (capitão no ranking)
- Estado anterior: rankings só dentro do bolão e em `/esquadrao/rankings`, ambos com login

## Escopo
- `GET /campeonatos/:id` (`public_championship_path`) sem login; busca com `Core::Championship.publicly_visible.find` (privado dá 404) e `authorize @championship, :public_show?`
- Abas `?tab=times|partidas|bolao|esquadrao`: classificação pelo `Simulador::StandingsCalculator` com as partidas encerradas, partidas uma rodada por vez (`?rodada=`, padrão na rodada atual) e os dois rankings
- `Core::ChampionshipRankingsService` (pacote raiz, porque o Core não pode depender de Bolão nem de Cartola):
  - Bolão: maior pontuação de cada partida por usuário entre os bolões dele, somada; só registros mantidos
  - Esquadrão: o `SCORES_JOIN` do `Cartola::RankingsService`, com a dobra do capitão, agrupado por (campeonato, usuário)
  - `.top(championships, limit: 3)` atende a home com 2 queries agrupadas; empates dividem a posição; o nome vem de `public_display_name`
- `Ui::LeaderboardTableComponent`: 4 estados, variante `compact:` e colunas extras

## Paths
- `config/routes.rb`, `app/controllers/championships_controller.rb`, `app/policies/core/championship_policy.rb`
- `app/services/core/championship_rankings_service.rb`
- `app/components/ui/leaderboard_table_component.{rb,html.erb}`, `spec/components/previews/ui/leaderboard_table_component_preview.rb`
- `app/views/championships/{show,_times,_partidas,_bolao,_esquadrao}.html.erb`

## Pronto quando
- As 4 abas respondem 200 sem login; privado → 404
- Um palpite em dois bolões do mesmo campeonato conta uma vez no ranking do Bolão
- Nenhum e-mail no HTML; sem consentimento, o nome é "Participante"

## Teste antes/depois
- Antes: `/campeonatos/1` → 404
- Depois: `spec/services/core/championship_rankings_service_spec.rb` (sem dupla contagem, Esquadrão com capitão, vazio, empate, anonimato); `spec/requests/championships_spec.rb` (200, abas, rodada, privado 404, sem e-mail); `spec/components/ui/leaderboard_table_component_spec.rb`
