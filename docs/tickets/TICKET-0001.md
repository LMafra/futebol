# TICKET-0001 — (a) Rails 8 + 4 engines + packwerk

- Deps: —
- Skill: [C]lean-build
- MCP: [neon] branch dev (opcional; fallback Postgres local)
- Spec: §1, ADR §1

## Paths
- `Gemfile`, `config/application.rb`, `packwerk.yml`, `package.yml`
- `engines/{core,bolao,cartola,simulador}/` (`*.gemspec`, `lib/<engine>/engine.rb`, `package.yml`)

## Pronto quando
- Gemfile com gems §1 (validar activeadmin × Rails 8.1)
- 4 engines montáveis, `isolate_namespace`
- packwerk: bolao/cartola/simulador dependem só de core; `bin/packwerk check` verde

## Teste antes/depois
- Antes: `bin/packwerk check` falha / `Core::Engine` indefinido
- Depois: `spec/engines/boot_spec.rb` — `expect(defined?(Core::Engine)).to be_truthy` para as 4 engines; `bin/packwerk check` exit 0
