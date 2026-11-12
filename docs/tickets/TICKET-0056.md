# TICKET-0056 — Papéis (enum) e gestor do campeonato (`manager_id`)

- Deps: TICKET-0014, TICKET-0015
- Skill: [W]tdd
- MCP: —
- Spec: §8 (autenticação e papéis)
- Estado anterior: `core_users.admin` boolean; campeonatos sem dono; torcedor, admin e visitante só

## Escopo
- `core_users.role` (`user`, `manager`, `admin`) e `manager_status` (`none`, `pending`, `approved`, `rejected`), com `prefix` nos enums para não colidir com `admin` e com `ActiveRecord::Base.none`
- `Core::User#manager?` exige `role_manager?` e `manager_approved?`; `admin?` usa o enum com fallback na coluna `admin` (migração gradual)
- `core_championships.manager_id` opcional, FK para `core_users`, índice concorrente e validação em migration separada
- Backfill: usuários com `admin = true` viram `role: :admin`
- `AnonymizeService` zera papel e `manager_status` na exclusão LGPD

## Paths
- `engines/core/db/migrate/20261031000043_add_role_and_manager_status_to_core_users.rb`
- `engines/core/db/migrate/20261031000044_backfill_role_from_admin_on_core_users.rb`
- `engines/core/db/migrate/20261031000045_add_manager_to_core_championships.rb`
- `engines/core/db/migrate/20261031000046_validate_manager_foreign_key_on_core_championships.rb`
- `engines/core/app/models/core/{user,championship}.rb`, `app/services/users/anonymize_service.rb`
- `config/locales/pt-BR.yml`, `spec/factories/users.rb`, `spec/seeds_spec.rb`

## Pronto quando
- Gestor aprovado é `manager?`; pendente ou recusado não
- Campeonato pode ter `manager`; `can_manage?(championship)` cobre admin ou gestor dono
- Seed e factories cobrem os três papéis

## Teste antes/depois
- Antes: só `user.admin?` boolean
- Depois: specs de model/factory; `db:seed` cria `gestor@demo.local` como gestor aprovado com campeonato atribuído
