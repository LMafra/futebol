# TICKET-0038 — Consentimento de perfil público e /minha-conta

- Deps: TICKET-0018, TICKET-0028
- Skill: [W]tdd
- MCP: —
- Spec: §8 (LGPD)
- Estado anterior: nenhum consentimento para expor o nome; rankings só existiam com login

## Escopo
- Coluna `core_users.public_profile_consented_at` (datetime, nulo); usuários antigos ficam anônimos
- `Core::User#public_profile_consented?` e `#public_display_name`: "Lucas M." com consentimento, "Participante" sem; o e-mail nunca aparece em área pública
- Signup: checkbox opcional, desmarcado, "Autorizo exibir meu nome (primeiro nome + inicial) nos rankings públicos do Craquefy"
- `resource :account, path: 'minha-conta', only: %i[show update]`: nome e e-mail só leitura e o toggle; `AccountPolicy` headless (`user.present?`)
- `Users::PublicProfileConsentService` grava AuditLog `user.public_profile_consent_granted`/`revoked` com IP; `Users::AnonymizeService` zera o consentimento

## Paths
- `engines/core/db/migrate/20261031000038_add_public_profile_consented_at_to_core_users.rb`, `engines/core/app/models/core/user.rb`
- `app/components/ui/signup_form_component.*`, `app/controllers/users_controller.rb`, `app/views/users/new.html.erb`
- `app/controllers/accounts_controller.rb`, `app/policies/account_policy.rb`, `app/views/accounts/show.html.erb`
- `app/services/users/{public_profile_consent_service,anonymize_service}.rb`

## Pronto quando
- Signup com e sem consentimento; `/minha-conta` exige login, mostra os dados e alterna o consentimento com AuditLog
- Conta anonimizada perde o consentimento

## Teste antes/depois
- Antes: `/minha-conta` → 404
- Depois: `spec/models/core/user_spec.rb`, `spec/requests/users_spec.rb`, `spec/requests/accounts_spec.rb`, `spec/services/users/anonymize_spec.rb`
