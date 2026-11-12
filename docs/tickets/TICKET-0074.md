# TICKET-0074 — Remover Ações rápidas / Atalhos do 1º viewport

- Deps: TICKET-0070, TICKET-0073
- Skill: [W]tdd
- MCP: —
- Spec: blueprint work-queue (Hick / CTAs concorrentes)

## Escopo
- Remover o bloco `Ações rápidas` do dashboard Admin (`data-role="admin-quick-actions"`)
- Remover o nav `Atalhos` do dashboard Gestor (`data-role="gestor-shortcuts"`)
- Mover **Criar campeonato** / **Novo campeonato** para CTA outline no header da página (não filled no 1º viewport)
- 1º viewport = KPIs + início da fila de trabalho (sem grid de atalhos globais)

## Paths
- `app/views/admin/dashboard/_scoring.html.erb`
- `app/views/gestor/dashboard/_index.html.erb`
- `spec/requests/admin/dashboard_spec.rb`
- `spec/requests/gestor/dashboard_spec.rb`

## Pronto quando
- Specs não esperam `admin-quick-actions` / `gestor-shortcuts`
- Criar campeonato acessível via header outline; gate `test` verde

## Teste antes/depois
- Antes: KPIs + 4–5 atalhos no mesmo peso visual
- Depois: KPIs + fila; setup discreto no header
