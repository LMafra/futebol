# TICKET-0073 — EmptyState, mobile e skeleton

- Deps: TICKET-0072
- Skill: [W]tdd
- MCP: —

## Escopo
- `Ui::EmptyStateComponent` (SVG, título, descrição, CTA) no blank slate e no painel do gestor
- Sidebar colapsável abaixo de `md` (768px) com toggle no header
- KPIs em 1 coluna no mobile; skeleton já em `AdminTableComponent` (`:loading`)
- Specs `empty_state_component_spec`, `mobile_spec`

## Paths
- `app/components/ui/empty_state_component.*`
- `app/views/active_admin/_site_sidebar.html.erb`, `_site_header.html.erb`
- `app/views/layouts/active_admin.html.erb`
- `spec/requests/admin/mobile_spec.rb`

## Pronto quando
- EmptyState · toast (0072) · sidebar responsiva · skeletons · specs verdes

## Teste antes/depois
- Antes: blank slate genérico; sidebar só em `xl`
- Depois: EmptyState Placar; collapse em `< md`
