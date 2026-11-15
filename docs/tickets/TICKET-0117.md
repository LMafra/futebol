# TICKET-0117 — Filtros com chips e views salvas

- Deps: TICKET-0116
- Skill: [W]tdd
- MCP: —

## Escopo
- `Ui::FilterBarComponent` (controles + chips + Limpar todos + views)
- Views: Minhas Pendências, Rodada Atual, Todas as Partidas
- Alternância Lista | Por Rodada
- Empty state com "Limpar Filtros"

## Paths
- `app/components/ui/filter_bar_component*`
- `app/helpers/admin_filter_chips_helper.rb`
- `app/views/active_admin/_sidebar.html.erb`
- `app/admin/matches.rb`, `app/admin/gestor/matches.rb`
