# TICKET-0070 — Dashboards status-first (8/4)

- Deps: TICKET-0066, TICKET-0069
- Skill: [W]tdd
- MCP: —

## Escopo
- Admin: 4 KPIs (campeonatos, ao vivo, pendentes de finalização, gestores pendentes) + ações rápidas 2×2 + últimas partidas
- Gestor: cards de campeonato → 3 KPIs → próximas partidas com Finalizar
- Grade 8/4; tipografia `font-numeric text-3xl`; borda esquerda 3px

## Paths
- `app/admin/dashboard.rb`, `app/views/admin/dashboard/_scoring.html.erb`
- `app/admin/gestor/dashboard.rb`, `app/views/gestor/dashboard/_index.html.erb`
- `spec/requests/admin/dashboard_spec.rb`, `spec/requests/gestor/dashboard_spec.rb`

## Pronto quando
- 4 KPIs admin; cards gestor; 8/4; gate verde

## Teste antes/depois
- Antes: métricas genéricas / atalhos laterais
- Depois: status-first + grade 8/4
