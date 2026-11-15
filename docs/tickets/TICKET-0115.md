# TICKET-0115 — Dashboard com Action Center e KPIs

- Deps: TICKET-0114
- Skill: [W]tdd
- MCP: —
- Spec: docs/design/0002 §hierarquia, 0003 KpiCard/ActionCenter

## Escopo
- `Ui::KpiCardComponent` (normal/zero/alert) e `Ui::ActionCenterComponent` (urgência + empty)
- Admin: hero + 4 KPIs acionáveis + Central de ações + Últimas ações
- Gestor: 4 KPIs (pendentes, lances, próxima rodada, inconsistências) + Central + Próximas partidas
- Clique no KPI filtra Action Center via `?urgency=`

## Paths
- `app/components/ui/kpi_card_component*`
- `app/components/ui/action_center_component*`
- `app/admin/dashboard.rb`, `app/views/admin/dashboard/_scoring.html.erb`
- `app/admin/gestor/dashboard.rb`, `app/views/gestor/dashboard/_index.html.erb`
- `app/services/gestor/match_queue.rb`

## Pronto quando
- [ ] KpiCard com 3 estados
- [ ] ActionCenter agrupado por urgência
- [ ] Admin e Gestor com 4 KPIs + Action Center
- [ ] KPI filtra Action Center
- [ ] Specs verdes
