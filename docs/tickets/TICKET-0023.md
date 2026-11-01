# TICKET-0023 — Bolão: criar e entrar em pool

- Deps: TICKET-0014, TICKET-0011
- Skill: implement-spec (indisponível localmente → [W]tdd)
- MCP: [neon] dev para `db:migrate` (opcional; fallback local)
- Spec: §2 (Bolão `pools`), §5 (4 estados), §6 (PoolPolicy); ADR 0001 §5 (Pundit)

## Paths
- `engines/bolao/db/migrate/*_create_bolao_pool_memberships.rb`, `engines/bolao/db/migrate/*_add_code_to_bolao_pools.rb`
- `engines/bolao/app/models/bolao/{pool,pool_membership}.rb`
- `app/controllers/bolao/pools_controller.rb`, `config/routes.rb` (`resources :pools, only: %i[index new create show destroy]` + `post :join, on: :collection`)
- `app/policies/bolao/pool_policy.rb` (já existe vazia; também usada pelo ActiveAdmin via `PunditAdapter`)
- `app/components/pools/{index,show,new}_component.{rb,html.erb}`, `spec/components/previews/pools/*_preview.rb`
- `spec/requests/bolao/pools_spec.rb`, `spec/models/bolao/pool_membership_spec.rb`, `spec/policies/bolao/pool_policy_spec.rb`

## Pronto quando
- `bolao_pool_memberships(pool_id, user_id, joined_at not null)` + índice unique `(pool_id, user_id)`; `Pool has_many :members, through: :memberships`
- `bolao_pools.code` string(6) not null, índice unique, gerado no `before_validation :on create` (alfanumérico maiúsculo, sem `0/O/1/I`), retry em colisão
- `create` cria o pool e a membership do owner na mesma transação; `join` recebe `code`, cria a membership e redireciona para `show`
- PoolPolicy: `index?`/`create?`/`join?` = usuário logado; `show?` = membro ou admin; `destroy?` = owner ou admin; `Scope#resolve` = pools onde o usuário é membro (admin vê todos)
- Admin mantém o acesso atual em `/admin/pools` (`spec/requests/admin/resources_spec.rb` segue verde)
- Componentes `Pools::Index/Show/New` com `default | loading | empty | error` (`Ui::BaseComponent`) e previews Lookbook

## Teste antes/depois
- Antes: não há tela pública de pools; `bolao_pools` não tem `code` e não existe `PoolMembership`
- Depois: request spec com 6 exemplos:
  1. `POST /pools` cria o pool, a membership do owner e um `code` de 6 caracteres
  2. dois pools criados recebem `code` diferentes (unique; colisão forçada → novo código)
  3. `POST /pools/join` com código válido → membership criada, redirect para o pool
  4. entrar 2× no mesmo pool → erro (sem nova membership; flash de erro / 422)
  5. só o owner deleta: não-owner → 403/redirect com alert; owner → pool removido
  6. não-membro em `GET /pools/:id` → 403
