# TICKET-0071 — Tabelas pitch + barra de filtros

- Deps: TICKET-0065, TICKET-0070
- Skill: [W]tdd
- MCP: —

## Escopo
- `Ui::AdminTableComponent` + `.data-table`: thead pitch, zebra, `tabular-nums`
- Ações de linha com SVG + `title`
- Filtros ActiveAdmin acima da tabela (`admin-filter-bar`)
- Specs `admin_table_component_spec` / `table_spec`

## Paths
- `app/components/ui/admin_table_component.*`
- `app/views/active_admin/_sidebar.html.erb`
- `app/views/active_admin/resource/_index_table_actions_default.html.erb`
- `app/assets/stylesheets/active_admin.css`
- `spec/requests/admin/table_spec.rb`

## Pronto quando
- Header pitch · zebra/nums · ações SVG · filtros visíveis · specs verdes

## Teste antes/depois
- Antes: filtros na lateral estreita; ações texto
- Depois: barra de filtros + ícones
