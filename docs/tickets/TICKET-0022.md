# TICKET-0022 — db/seeds.rb real (substituir puts "seeds ok")

- Deps: TICKET-0002
- Skill: [W]tdd
- MCP: [neon] dev (opcional; nunca prod)
- Spec: §3 (seeds idempotentes, `belongs_to` sem array)

## Paths
- `db/seeds.rb`, `db/seeds/{teams,championships,matches,users}.rb`
- `spec/seeds_spec.rb`

## Pronto quando
- 20 times (Série A), 1 campeonato, 38 rodadas de partidas com `match_date`, 1 admin (senha via ENV)
- Tudo via `find_or_create_by!(external_id:)`; cada `belongs_to` recebe 1 registro
- Bloqueado em produção (`abort if Rails.env.production?` salvo ENV explícito)

## Teste antes/depois
- Antes: `db:seed` só imprime "seeds ok"
- Depois: `expect { 2.times { Rails.application.load_seed } }` → contagens iguais após a 1ª carga; admin existe
