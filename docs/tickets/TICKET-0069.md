# TICKET-0069 — Navegação por tarefa + ícones SVG

- Deps: TICKET-0068
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-critique (sem emoji)

## Escopo
- Reparent de menus ActiveAdmin em tarefas (Meus campeonatos / Partidas / Participantes / Configurações / Auditoria)
- Ícones SVG Heroicons-style por seção
- Gestor esconde itens só-admin
- Spec `navigation_spec`

## Paths
- `app/admin/**/*.rb` (menu parent)
- `app/helpers/admin_helper.rb` (`ADMIN_NAV_ICON_PATHS`)
- `spec/requests/admin/navigation_spec.rb`

## Pronto quando
- Nav por tarefa com SVG; specs verdes

## Teste antes/depois
- Antes: menus planos / misturados
- Depois: seções por tarefa com ícone
