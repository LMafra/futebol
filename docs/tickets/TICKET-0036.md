# TICKET-0036 — Rebranding Craquefy

- Deps: TICKET-0032, TICKET-0034, TICKET-0037
- Skill: [W]tdd
- MCP: —
- Spec: [glossário](../glossary.md) (Craquefy)
- Estado anterior: "Futebol" no `<title>`, no `application-name`, no sufixo de cerca de 12 páginas, no manifest, no preview de componentes e no título do admin

## Escopo
- Marca em `brand.name`, `brand.tagline` e `brand.description` (`config/locales/pt-BR.yml`), lidos por `BrandHelper#brand` e `#brand_title(*partes)` ("Meus bolões · Craquefy")
- Troca em: `<title>` padrão, `application-name`, meta description nova, sufixo das páginas, `layouts/component_preview`, `pwa/manifest.json.erb`, `errors/forbidden`, assinatura de `layouts/mailer.{html,text}.erb` e `site_title` do ActiveAdmin (proc com `I18n.t`, avaliado por request)
- README (título, tagline, nota "Repo GitHub: futebol; marca: Craquefy." e exemplo de `RESEND_FROM`) e glossário (Craquefy, Esquadrão, Scout)
- Não muda: repositório, engines, tabelas, classes, `service.name` do OpenTelemetry e e-mails de teste (`@futebol.test`)

## Paths
- `config/locales/pt-BR.yml`, `app/helpers/brand_helper.rb`, `config/initializers/active_admin.rb`
- `app/views/layouts/{application,component_preview,mailer}.*`, `app/views/pwa/manifest.json.erb`, as views com `content_for(:title)`
- `README.md`, `docs/glossary.md`

## Pronto quando
- Nenhum "Futebol" em texto visível do app, do admin e dos e-mails
- Título, meta, manifest e assinatura do e-mail vêm do locale

## Teste antes/depois
- Antes: `<title>Futebol</title>`
- Depois: `spec/requests/brand_spec.rb` (título e meta da home, sufixo das páginas, título do admin, assinatura do e-mail de senha e manifest)
