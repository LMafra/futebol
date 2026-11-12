# TICKET-0062 — Tabela de comentários do ActiveAdmin

- Deps: TICKET-0010, TICKET-0059
- Skill: [W]tdd
- MCP: —
- Spec: §6
- Estado anterior: `config.comments = false` implícito; sem tabela `active_admin_comments`

## Escopo
- Migration `active_admin_comments` no host app (`namespace`, `body`, `resource` e `author` polimórficos, índice em `namespace`)
- `config.comments = true` no admin global; `gestor.comments = false` no bloco do namespace gestor
- Comentários só para admin (`ApplicationPolicy`); gestor recebe 403 em `/admin/comments`; `/gestor/comments` continua 404 pela rota dedicada
- Admin cria comentário em recurso (ex.: campeonato) e visualiza em `/admin/comments`

## Paths
- `db/migrate/20261031000048_create_active_admin_comments.rb`, `db/schema.rb`
- `config/initializers/active_admin.rb`, `config/routes.rb` (catch-all gestor/comments)
- `app/admin/championships.rb` (`active_admin_comments_for resource` no show)
- `spec/requests/admin/comments_spec.rb`

## Pronto quando
- Tabela existe e o admin persiste comentários com namespace `admin`
- Gestor não acessa comentários em nenhum namespace
- `database_consistency` sem ruído novo (ou entrada em `config/database_consistency.todo.yml` se polimórficos exigirem)

## Teste antes/depois
- Antes: comentários desabilitados; migration ausente
- Depois: `spec/requests/admin/comments_spec.rb`; `spec/requests/gestor/namespace_spec.rb` mantém 404 em `/gestor/comments`
