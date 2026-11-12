# TICKET-0059 — Namespace `/gestor` e logins por área

- Deps: TICKET-0058, TICKET-0010, TICKET-0033
- Skill: [W]tdd
- MCP: —
- Spec: §8
- Estado anterior: um único login em `/entrar`; só `/admin` para operação

## Escopo
- ActiveAdmin namespace `:gestor` (`config.namespace :gestor`): `authenticate_manager!`, `Gestor::PunditAdapter`, comentários desligados, batch/download off
- Recursos em `app/admin/gestor/`: campeonatos (com `manager_id` na criação), times, jogadores, partidas, regras do Bolão, bolões e escalações (somente leitura onde a policy nega escrita)
- Rotas `GET /admin/login` e `GET /gestor/login` com campo oculto `area`; `SessionsController` recusa conta sem acesso à área
- Redirect pós-login: admin → `/admin`, gestor → `/gestor`, torcedor → `/`
- Rodapé: "Área do gestor" para admin ou gestor logado; gestor leva 403 em `/admin`
- Rota catch-all `404` em `/gestor/comments`, porque o gem registra comentários em todo namespace

## Paths
- `config/initializers/active_admin.rb`, `config/routes.rb`, `app/controllers/{sessions_controller,application_controller}.rb`
- `app/controllers/concerns/authentication.rb`, `app/views/sessions/new.html.erb`
- `app/admin/gestor/*.rb`, `app/helpers/gestor_helper.rb`, `app/controllers/concerns/gestor_resource.rb`
- `app/views/layouts/application.html.erb`
- `spec/requests/{authentication_spec,gestor/namespace_spec}.rb`

## Pronto quando
- Gestor aprovado e admin entram em `/gestor`; torcedor e gestor pendente não
- Login por área não cria sessão indevida
- Listagens do gestor só mostram campeonatos com `manager_id` do usuário

## Teste antes/depois
- Antes: `post session` com gestor ia para `/admin` ou home sem checar área
- Depois: `spec/requests/authentication_spec.rb`, `spec/requests/gestor/namespace_spec.rb`
