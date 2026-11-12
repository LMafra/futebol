# TICKET-0058 — Policies com escopo por campeonato

- Deps: TICKET-0056, TICKET-0015, TICKET-0010
- Skill: [W]tdd
- MCP: —
- Spec: §6 (autorização)
- Estado anterior: `ApplicationPolicy` só distinguia admin; gestor não tinha escopo

## Escopo
- `ApplicationPolicy` com `manages?` / `manager?` e `Scope#resolve`: admin vê tudo, gestor `managed_scope`, demais `none`
- Policies `Core::{Championship,Team,Player,Match}`: index/create para gestor; show/update/destroy só quando `manage?` no campeonato (times travados se ligados a campeonato de outro gestor)
- `Bolao::PoolPolicy` e `Cartola::LineupPolicy` ganham `manage?` no campeonato para telas futuras do gestor
- `Core::MatchPolicy`: gestor lista e vê partidas dos próprios campeonatos; criar/alterar partida continua admin no `/admin` (gestor usa namespace `:gestor`)
- Specs em `spec/policies/gestor/core/*` para match e escopo

## Paths
- `app/policies/application_policy.rb`, `app/policies/core/{championship,team,player,match,user}_policy.rb`
- `app/policies/bolao/pool_policy.rb`, `app/policies/cartola/lineup_policy.rb`
- `app/policies/gestor/**/*_policy.rb`, `app/policies/gestor/pundit_adapter.rb`
- `spec/policies/gestor/core/match_policy_spec.rb`

## Pronto quando
- Gestor não autorizado recebe 403 ou escopo vazio nas listagens
- Admin mantém acesso global no `/admin`
- `managed_championships` e `managed_by` são a fonte do escopo

## Teste antes/depois
- Antes: policies só `admin?`
- Depois: policy specs por papel e campeonato; Prosopite limpo nas listagens do gestor
