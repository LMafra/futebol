# TICKET-0075 — Fila Admin: gestores pendentes com Aprovar inline

- Deps: TICKET-0057, TICKET-0079, TICKET-0081
- Skill: [W]tdd
- MCP: —
- Spec: blueprint Admin (work queue de triagem)

## Escopo
- No dashboard Admin, logo abaixo dos KPIs: tabela de pedidos de gestor pendentes (Nome · E-mail · Pedido em · Ações).
- Contador "N pendentes · M há mais de 24h"; selo "+24h" na linha.
- Ordenação pela data do `AuditLog` `user.manager_requested` (fallback `updated_at`), mais antigos primeiro. Assim, os de mais de 24h vêm antes.
- **Aprovar**: `button_to` PUT primário (1 clique), volta ao dashboard com flash "Gestor aprovado: {nome}.".
- **Recusar**: `<details>` secundário com textarea "Motivo da recusa (obrigatório)" e botão danger. Motivo vazio volta ao dashboard com o pedido intacto, `aria-invalid` + `aria-describedby` no campo e o `<details>` aberto.
- O motivo vai para `metadata.reason` do `AuditLog` `user.manager_rejected` (máx. 500 caracteres); o e-mail ao usuário não muda.
- O show do usuário usa o mesmo formulário de recusa (painel "Recusar pedido de gestor"); a recusa sem motivo deixou de existir.
- Empty state com `Ui::EmptyStateComponent` quando ninguém espera.
- A organização do pedido não existe no modelo; a coluna ficou como E-mail.

## Paths
- `app/services/users/pending_manager_queue.rb` (novo)
- `app/services/users/review_manager_request_service.rb` (`reason:`)
- `app/admin/users.rb` (`return_to`, motivo obrigatório)
- `app/admin/dashboard.rb`, `app/views/admin/dashboard/_pending_managers.html.erb`
- `app/views/admin/users/_reject_manager_form.html.erb`
- `config/initializers/active_admin.rb` (`flash_keys_to_except` com `manager_reject_error`)

## Pronto quando
- Triagem de 1 gestor pendente sem navegar para `/users`
- Contador de exceção (pendentes / >24h) visível no 1º viewport
- Gate `test` verde

## Teste antes/depois
- Antes: KPI "gestores pendentes" + link genérico para scope
- Depois: fila de triagem com Aprovar/Recusar na linha; no navegador, recusar com motivo em branco → toast "Informe o motivo da recusa.", campo `aria-invalid=true`, `<details>` aberto, pedido segue pendente
