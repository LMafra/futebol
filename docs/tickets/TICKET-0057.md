# TICKET-0057 — Pedido e aprovação de gestor

- Deps: TICKET-0056
- Skill: [W]tdd
- MCP: —
- Spec: §8
- Estado anterior: nenhum fluxo para virar gestor; admin não listava pedidos

## Escopo
- Torcedor solicita em `GET/POST /gestor/solicitar` (`ManagerRequestsController` + `ManagerRequestPolicy`)
- `Users::RequestManagerService` marca `manager_status: :pending` e grava `AuditLog` `user.manager_requested`
- E-mail ao admin (`ManagerRequestMailer`); usuário vê status em `/minha-conta` (pendente, recusado, solicitar de novo)
- ActiveAdmin **Usuários** (index/show): filtro e escopo "Pedidos pendentes"; ações **Aprovar gestor** / **Recusar pedido**
- `Users::ReviewManagerRequestService` + `Core::UserPolicy#approve_manager?` / `#reject_manager?`; aprovação define `role: :manager` e `manager_status: :approved`

## Paths
- `app/controllers/manager_requests_controller.rb`, `app/policies/manager_request_policy.rb`
- `app/services/users/{request_manager,review_manager_request}_service.rb`
- `app/mailers/manager_request_mailer.rb`, `app/views/manager_requests/new.html.erb`, `app/views/manager_request_mailer/*`
- `app/admin/users.rb`, `app/policies/core/user_policy.rb`, `app/views/accounts/show.html.erb`
- `config/routes.rb` (`gestor/solicitar` antes das rotas do ActiveAdmin)

## Pronto quando
- Torcedor envia pedido; gestor pendente não acessa `/gestor`
- Admin aprova ou recusa no show do usuário; AuditLog registra a decisão
- Gestor/recusado/admin não vê o formulário de novo pedido sem necessidade

## Teste antes/depois
- Antes: `/gestor/solicitar` inexistente
- Depois: request specs do fluxo de pedido; policy specs de `Core::UserPolicy`; integração com ActiveAdmin via request specs de usuários (quando existirem)
