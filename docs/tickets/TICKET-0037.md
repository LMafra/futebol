# TICKET-0037 — Interface em pt-BR com rails-i18n

- Deps: TICKET-0010, TICKET-0014
- Skill: [W]tdd
- MCP: —
- Spec: §8
- Estado anterior: `default_locale` `:en`; flashes de sessão e senha, e-mail de redefinição e ActiveAdmin em inglês

## Escopo
- Gem `rails-i18n`; `config.i18n.default_locale = :'pt-BR'` e `available_locales = %i[pt-BR en]`
- `activemodel.attributes` movidos de `en.yml` para `pt-BR.yml`
- Flashes de `SessionsController` e `PasswordsController` e o e-mail de redefinição de senha em português
- O ActiveAdmin passa a usar o pt-BR dele

## Paths
- `Gemfile`, `Gemfile.lock`, `config/application.rb`, `config/locales/{en,pt-BR}.yml`
- `app/controllers/{sessions,passwords}_controller.rb`, `app/mailers/passwords_mailer.rb`, `app/views/passwords_mailer/reset.{html,text}.erb`

## Pronto quando
- Datas, validações, flashes e admin em português sem texto em inglês nas telas cobertas
- Quem baixar a branch roda `bundle install` (gem nova)

## Teste antes/depois
- Antes: flash "Try another email address or password."
- Depois: `spec/requests/sessions_spec.rb`, `spec/requests/passwords_spec.rb` (novo: flashes e e-mail) e `spec/requests/admin/dashboard_spec.rb` com os textos em português
