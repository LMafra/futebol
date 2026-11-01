# TICKET-0012 (v2) — (l) CI + pre-commit + deploy Render/Neon + R2 + Resend

- Deps: TICKET-0001, TICKET-0002, TICKET-0010, TICKET-0014, TICKET-0015
- Skill: [W]setup-pre-commit (adaptado a git hook), [C]verify-and-stop
- MCP: [render] deploy/logs · [neon] só dev/test (prod via DATABASE_URL manual) · [r2] buckets futebol-dev/futebol-prod · [resend] e-mail teste
- Spec: §9

## Paths
- `.github/workflows/ci.yml` (rubocop, packwerk, rspec, brakeman, grep anti-AI)
- `.githooks/pre-commit`, `render.yaml` (web + worker), `config/storage.yml` (r2), `config/environments/production.rb` (Resend SMTP/API)

## Pronto quando
- CI verde em PR; pre-commit roda rubocop staged
- Render: healthcheck `/up`; keep-alive (cron externo ping `/up` a cada 10 min)
- ActiveStorage service `r2`; ActionMailer via Resend
- Deploy só com auth (0014) e autorização (0010, 0015) ativas

## Teste antes/depois
- Antes: sem CI; `curl /up` falha
- Depois: workflow verde; `curl -fsS https://<app>.onrender.com/up` 200; e-mail teste recebido (Resend); upload R2 visível em `futebol-dev`
