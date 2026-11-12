# TICKET-0066 — Dashboards admin e gestor

- Deps: TICKET-0065, TICKET-0060
- Skill: [W]tdd
- MCP: —
- Spec: design grid 8/4 e 3/9

## Escopo
- Dashboard admin: métricas (campeonatos/times/jogadores/partidas) + atalhos SVG + 8/4
- Dashboard gestor: cards por campeonato + atalhos + grid 3/9
- Specs `dashboard_spec` admin/gestor

## Paths
- `app/admin/dashboard.rb`
- `app/views/admin/dashboard/_scoring.html.erb`
- `app/views/gestor/dashboard/_index.html.erb`
- `spec/requests/admin/dashboard_spec.rb`
- `spec/requests/gestor/dashboard_spec.rb`

## Pronto quando
- Admin mostra card Campeonatos; gestor mostra nome do campeonato gerenciado
- Layout assimétrico (não 3 cards iguais)
- Specs verdes

## Teste antes/depois
- Antes: painéis gray genéricos
- Depois: métricas/cards Placar
