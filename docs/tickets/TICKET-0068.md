# TICKET-0068 — Layout Admin/Gestor (sidebar paper + chrome)

- Deps: TICKET-0063, TICKET-0064
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-direction / critique

## Escopo
- Extrair `_site_sidebar` com superfície `paper`/`rule`
- Header `pitch` + footer `graphite` unificados
- Spec `layout_spec` (header/sidebar/footer)

## Paths
- `app/views/active_admin/_site_sidebar.html.erb`
- `app/views/layouts/active_admin.html.erb`
- `spec/requests/admin/layout_spec.rb`

## Pronto quando
- Sidebar com `data-role="craquefy-admin-sidebar"`; gate `test` verde

## Teste antes/depois
- Antes: chrome misturado com defaults AA
- Depois: sidebar Placar dedicada
