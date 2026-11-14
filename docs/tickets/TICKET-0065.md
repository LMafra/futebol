# TICKET-0065 — Tabelas e formulários Placar no ActiveAdmin

- Deps: TICKET-0063, TICKET-0064
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-direction

## Escopo
- CSS `.data-table` thead pitch + zebra paper; `Ui::AdminTableComponent`
- Formtastic + `AdminHelper` com `border-rule` / `bg-paper` / `bg-cartola text-ink`
- Specs `table_spec`, `form_spec`, component spec

## Paths
- `app/assets/stylesheets/active_admin.css`
- `config/initializers/active_admin_placar_table.rb`
- `config/initializers/formtastic_placar.rb`
- `app/helpers/admin_helper.rb`
- `app/components/ui/admin_table_component.*`
- `spec/requests/admin/table_spec.rb`, `form_spec.rb`

## Pronto quando
- Index championships com thead `bg-pitch`
- Form championship com classes Placar no HTML
- Specs verdes

## Teste antes/depois
- Antes: gray/blue Flowbite
- Depois: tokens Placar em tabelas e forms
