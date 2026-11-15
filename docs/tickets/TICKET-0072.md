# TICKET-0072 — Formulários em seções + toast

- Deps: TICKET-0071
- Skill: [W]tdd
- MCP: —

## Escopo
- Campeonato (admin/gestor): seções Dados · Esquadrão · Bolão · Premiação
- `Ui::FormSectionComponent` + `Ui::ToastComponent`
- Notice "Campeonato atualizado"; aprovação de gestor via Turbo Stream (badge + toast)

## Paths
- `app/admin/championships.rb`, `app/admin/gestor/championships.rb`
- `app/admin/users.rb`
- `app/components/ui/form_section_component.*`, `toast_component.*`
- `spec/requests/admin/form_spec.rb`, `manager_approval_spec.rb`

## Pronto quando
- 4 seções · inputs `border-rule` · submit `bg-cartola` · feedback · specs verdes

## Teste antes/depois
- Antes: inputs agrupados sem hierarquia clara
- Depois: seções nomeadas + toast
