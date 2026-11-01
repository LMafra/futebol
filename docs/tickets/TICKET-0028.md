# TICKET-0028 — Signup público

- Deps: TICKET-0011, TICKET-0014, TICKET-0019
- Skill: [W]tdd
- MCP: —
- Spec: §5 (4 estados), §6 (auth nativa); ADR 0001 §5
- Estado anterior: `/users/new` não existia; contas só pelo console (`Core::User.create!`). `Core::User` já validava e-mail (presença, unicidade, formato) e senha ≥ 8; `active` já tinha default `true`
- Numeração: o ADR 0003 cita "0028" como ticket derivado (`core_matches.round`); aquele número não chegou a existir no INDEX e o derivado foi absorvido pelo TICKET-0031

## Paths
- `app/controllers/users_controller.rb`, `config/routes.rb` (`resources :users, only: %i[new create]` + `get 'signup'`)
- `app/views/users/new.html.erb`, `app/views/sessions/new.html.erb` (link "Criar conta")
- `app/components/ui/signup_form_component.{rb,html.erb}`, `spec/components/previews/ui/signup_form_component_preview.rb`
- `engines/core/app/models/core/user.rb`, `app/services/users/anonymize_service.rb`
- `db/seeds/users.rb` (admin com nome), `db/seeds/demo.rb` (comentário), `README.md`
- `spec/requests/users_spec.rb`, `spec/requests/sessions_spec.rb`, `spec/models/core/user_spec.rb`, `spec/components/ui/signup_form_component_spec.rb`

## Pronto quando
- `GET /signup` e `GET /users/new` → 200 com o form (`Ui::SignupFormComponent`: nome, e-mail, senha, confirmação)
- `POST /users` cria o usuário ativo, chama `start_new_session_for` e redireciona para `/` com notice "Conta criada"
- Erros → 422 com mensagem por campo (`aria-invalid` + `aria-describedby`), em português
- `name` obrigatório só no create (contas antigas, como o admin do seed de produção, não têm nome)
- E-mail no domínio reservado da anonimização (`@invalid`, `Core::User::ANONYMIZED_EMAIL_DOMAIN`) é recusado: o `Users::AnonymizeService` troca o e-mail original por `anon-<uuid>@invalid`, então é esse domínio que não pode ser cadastrado
- Rate limit do TICKET-0019 (`limit_auth_attempts`: 5 tentativas / 3 min por IP) em `UsersController#create` → 429
- Link "Criar conta" no login

## Teste antes/depois
- Antes: `GET /signup` → 404
- Depois: `spec/requests/users_spec.rb` com 6 exemplos (signup válido cria user + sessão, redirect com notice, e-mail duplicado 422, senha curta 422, e-mail inválido 422, 6ª tentativa 429); `sessions_spec` cobre o link e o `GET /signup` 200
