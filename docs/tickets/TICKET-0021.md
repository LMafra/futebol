# TICKET-0021 — Solid Queue dashboard + Sentry

- Deps: TICKET-0012
- Skill: [W]tdd
- MCP: [render] logs do worker (opcional)
- Spec: §1 (sentry-ruby/sentry-rails ~> 7.2), §9

## Paths
- `Gemfile` (`mission_control-jobs`, `sentry-ruby`, `sentry-rails`)
- `config/routes.rb` (mount `MissionControl::Jobs::Engine` em `/jobs`), `config/initializers/sentry.rb`

## Pronto quando
- `/jobs` restrito a admin (constraint de sessão + `admin?`)
- Sentry: DSN via ENV, `environment`, `traces_sample_rate` baixo, filtra PII (`send_default_pii = false`)
- Jobs com `rescue` reportam a Sentry (ProcessMatchPointsJob, ProcessCsvImportJob)

## Teste antes/depois
- Antes: sem visibilidade de filas; erros só em log
- Depois: request spec `/jobs` não-admin → 404/redirect, admin → 200; `Sentry.capture_exception` recebido em spec com `Sentry::TestHelper`
