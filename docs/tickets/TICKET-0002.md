# TICKET-0002 — (b) Core models + seeds idempotentes

- Deps: TICKET-0001
- Skill: [W]tdd, [C]migration
- MCP: [neon] dev para `db:migrate` (nunca prod)
- Spec: §2, §3 (seeds)

## Paths
- `engines/core/db/migrate/*` (teams, championships, users, matches, audit_logs, csv_imports)
- `engines/core/app/models/core/*.rb`, `db/seeds.rb`

## Pronto quando
- Migrations com `add_check_constraint` (status, scored⇔timestamp, times distintos, placar ≥0)
- Seeds via `find_or_create_by!(external_id:)`; `belongs_to` recebe 1 registro (nunca array)
- `bin/rails db:seed` 2× → mesmas contagens

## Teste antes/depois
- Antes: `spec/models/core/match_spec.rb` falha (tabela inexistente); seed 2× duplica
- Depois: spec valida check constraints (`ActiveRecord::StatementInvalid` para home=away); `spec/seeds_spec.rb` roda seeds 2× e `expect { load seeds }.not_to change(Core::Match, :count)`
