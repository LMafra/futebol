# Handoff — Fase 5 (Scaffold) — ok

## Decisões
- Rails 8.1.2, Postgres, Tailwind (tailwindcss-rails 4), Solid Queue/Cache/Cable, sem Kamal/CI gerados
- Engines mountable em `engines/`, via `gem '<engine>', path:` no Gemfile; migrations anexadas ao app por initializer (`lib/<engine>/engine.rb`)
- 12 migrations vazias `# TODO: TICKET-0002|0004|0007`
- Stubs `NotImplementedError`: Scoring::Engine, RevertMatchPointsService, BroadcastUpdateService, 3 jobs, previews Bolão/Cartola
- 5 policies + ApplicationPolicy (PORO, sem gem pundit ainda)
- DB local: `docker run -d --name futebol-pg -e POSTGRES_PASSWORD=postgres -p 5440:5432 postgres:18`

## Status
- db:create/migrate/seed ok (local); zeitwerk ok; rspec 0 examples; rubocop 0 offenses
- Commits: 1b505bb, fbf0100

## Avisos
- Neon MCP ausente → local
- `.gitignore` recebeu 1 linha do gerador
