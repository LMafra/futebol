# TICKET-0079 — Bug: Aprovar/Recusar gestor não funcionam no Admin

- Deps: TICKET-0057, TICKET-0072
- Skill: [W]tdd
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
Os botões **Aprovar gestor** e **Recusar pedido** em `/admin/users/:id` usavam `data-turbo-method="put"` e `data-turbo-confirm`. O importmap do ActiveAdmin carrega só flowbite, rails-ujs e Stimulus (sem Turbo), então os atributos eram inertes: o clique virava `GET /admin/users/:id/approve_manager`, rota que só aceita PUT. O pedido de gestor não podia ser triado pela UI.

## Ambiente
- Desktop, Chromium 1208 (Playwright), Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23
- Usuário: admin (`admin@futebol.dev`)

## Severidade
Alta — fluxo de governança do Admin (aprovar gestor) bloqueado para todos os admins; o request spec chamava `put` direto e não detectava.

## Passos para reproduzir
1. Entrar como admin.
2. Abrir um usuário com `manager_status = pending` (`/admin/users/:id`).
3. Clicar em **Aprovar gestor**.

## Esperado
Confirmação “Aprovar este pedido de gestor?”, PUT, redirect para o usuário com flash “Gestor aprovado.”.

## Atual
Sem confirmação; navegação GET para a URL do `member_action` (erro de rota).

## Correção
- `action_item`s com `button_to … method: :put` + `data-confirm` (rails-ujs).
- `member_action`s respondem só HTML (`redirect_to` 303 + `notice`); removidos o ramo `turbo_stream` e o partial `admin/shared/_toast`.
- Spec: o show renderiza forms PUT sem `data-turbo-*`; approve/reject redirecionam com flash.

## Evidência
- Antes: `docs/checkpoints/ux-audit/before/admin-user-pending-1440.png`
- Depois (navegador real): diálogo “Aprovar este pedido de gestor?” → `/admin/users/8` com flash “Gestor aprovado.”

## Pronto quando
- Aprovar/Recusar funcionam por clique no Admin sem Turbo
- Gate `test` verde
