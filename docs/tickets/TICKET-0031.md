# TICKET-0031 — Simulador v1 "e se"

- Deps: TICKET-0011, TICKET-0026, TICKET-0030 (`core_matches.round`)
- Skill: [W]tdd
- MCP: —
- Spec: §10 (Simulador); [ADR 0003](../adr/0003-simulador.md)
- Estado anterior: engine `simulador` só com os arquivos gerados; nenhuma rota nem tela
- Numeração: o ADR 0003 chama este ticket de "0029"; o pré-requisito que ele numerava "0028" (`core_matches.round`) entrou no TICKET-0030

## Escopo conferido com o ADR 0003
- Público (sem login), sem persistência, cálculo síncrono, sem job: segue o ADR
- Rotas: as duas formas existem. As do ADR (`GET /simulador`, `POST /simulador/projecao`) e as pedidas no ticket (`GET /simulador/:championship_id`, `POST /simulador/:championship_id/preview`) apontam para o mesmo controller
- Desempate: segue o ADR (pontos, vitórias, saldo, gols pró, nome). O pedido do ticket (pontos, saldo, gols pró) é um subconjunto; onde divergem, vale o ADR
- Nome do service: `Simulador::StandingsCalculator` (pedido do ticket) no lugar de `Simulador::ProjectStandings` (ADR); mesmo papel: puro, sem ActiveRecord
- Fora desta v1: os atalhos "preencher em branco com empate" e "mandante vence" (opcionais no ADR §2)

## Paths
- Engine: `engines/simulador/app/services/simulador/standings_calculator.rb`, `engines/simulador/app/models/simulador/simulation.rb`
- App: `app/controllers/simulador/simulations_controller.rb`, `app/policies/simulador/simulation_policy.rb`, `app/helpers/simulador_helper.rb`, `app/views/simulador/simulations/{show,preview,rate_limited,_simulator}.html.erb`, `config/routes.rb`, `app/views/layouts/application.html.erb` (link no topo)
- UI: `app/components/ui/standings_table_component.*` (variação de posição e faixas de zona, opcionais)
- Admin: `app/admin/championships.rb` (botão "Simulador")

## Pronto quando
- `Simulador::StandingsCalculator.call(matches:, teams:, overrides: { match_id => { home:, away: } })` devolve a classificação ordenada, sem tocar o banco; jogo sem placar fica fora
- `Simulador::Simulation` (`Data.define(:championship_id, :guesses, :errors)`) aceita só partidas `scheduled`/`live` do campeonato, inteiros de 0 a 99, com erro por partida
- `GET` mostra a tabela atual (só jogos encerrados) e o formulário por rodada (jogos `live` pré-preenchidos); `fresh_when` por ETag (304)
- `POST` devolve o Turbo Frame `simulador` com a tabela projetada, variação de posição (glifo + rótulo) e zonas (Título, G4, G6, Z4); 422 com erros por partida; 429 após 30 projeções por minuto por IP
- Nada é gravado

## Teste antes/depois
- Antes: `/simulador` → 404
- Depois: `spec/services/simulador/standings_calculator_spec.rb` (tabela real, projeção com overrides, desempates, sem banco); `spec/models/simulador/simulation_spec.rb`; `spec/requests/simulador_spec.rb` (GET 200 público, `/simulador`, 304, 404, POST preview 200 sem gravar, rota do ADR, overrides inválidos 422, 429, link no admin); `spec/components/ui/standings_table_component_spec.rb` (variação e zonas)
