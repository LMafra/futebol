# TICKET-0060 — Painel do gestor e premiação

- Deps: TICKET-0059
- Skill: [W]tdd
- MCP: —
- Spec: §9 (operação do campeonato)
- Estado anterior: sem dashboard do gestor; premiação só conceitual

## Escopo
- Página registrada `Dashboard` no namespace `:gestor` com partial `gestor/dashboard/_index.html.erb`
- Classes `panel`, `panel-title`, `panel-body`, `data-table` e `status-tag` (mesmo vocabulário das telas do admin)
- `Gestor::ChampionshipOverview`: contadores por campeonato (times com partida, jogadores, partidas, agendadas, bolões) em poucas queries agrupadas
- Atalhos para criar campeonato, time, jogador, partida, regra do Bolão e pontuação
- Premiação: migration `prize_description` + `prize_rules` (jsonb) com `first_place`, `second_place`, `third_place`; gestor edita no formulário do campeonato; coluna "Premiação" no painel (`definida` / `a definir`)

## Paths
- `engines/core/db/migrate/20261031000047_add_prize_to_core_championships.rb`
- `engines/core/app/models/core/championship.rb` (`PRIZE_PLACES`, `prize?`)
- `app/admin/gestor/dashboard.rb`, `app/services/gestor/championship_overview.rb`
- `app/views/gestor/dashboard/_index.html.erb`, `app/admin/gestor/championships.rb`
- `spec/requests/manager_dashboard_spec.rb`

## Pronto quando
- `/gestor` (painel) lista só campeonatos do gestor com contadores coerentes
- Gestor define texto e prêmios por colocação; tabela do painel reflete `prize?`
- Estado vazio orienta a criar o primeiro campeonato

## Teste antes/depois
- Antes: `/gestor` era só o índice padrão do ActiveAdmin
- Depois: `spec/requests/manager_dashboard_spec.rb` (contadores, atalhos, update de premiação)
