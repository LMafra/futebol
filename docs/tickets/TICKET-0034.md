# TICKET-0034 — Cartola vira Esquadrão na interface e no admin

- Deps: TICKET-0025, TICKET-0030
- Skill: [W]tdd
- MCP: —
- Spec: §9 (fantasy); [glossário](../glossary.md) (Esquadrão)
- Estado anterior: "Cartola", "Cartoleiro" e "Cartoletas" em texto visível, rotas `/cartola` e menu "Cartola" no admin

## Escopo
- Só texto visível e URLs públicas: engine `cartola`, package, tabelas `cartola_*`, classes `Cartola::...` e o token CSS `bg-cartola` não mudam
- `modules.fantasy.name/tagline` no `config/locales/pt-BR.yml`, lidos por `BrandHelper#module_label(:fantasy)`
- Rotas `/esquadrao` (escalação) e `/esquadrao/rankings`; `/cartola` e `/cartola/rankings` respondem 301 preservando a query string; `/lineup` continua
- Textos: "Cartola" → "Esquadrão", "Cartoleiro" → "Técnico", "Cartoletas" → "Moedas" (o `C$` fica)
- Admin: menu "Esquadrão", `register_page 'EsquadraoRankings'`, recursos `as: 'EsquadraoScoringRule'` e `as: 'EsquadraoSquad'`; 301 de `/admin/cartolarankings`, `/admin/cartola_scoring_rules(/*)` e `/admin/squads(/*)`, declarados antes de `ActiveAdmin.routes`

## Paths
- `config/routes.rb`, `config/locales/pt-BR.yml`, `app/helpers/brand_helper.rb`
- `app/views/cartola/{lineups,rankings}/*`, `app/components/cartola/ranking_table_component.*`, `app/controllers/cartola/rankings_controller.rb`
- `app/admin/{esquadrao_rankings,esquadrao_scoring_rules,esquadrao_squads,championships,players}.rb`, `app/views/admin/esquadrao_rankings/_rankings.html.erb`, `app/views/admin/scoring_rule_tester/_panels.html.erb`

## Pronto quando
- Nenhum "Cartola" em texto visível das telas do usuário e do admin
- As URLs antigas, públicas e do admin, respondem 301 para as novas, com a query string

## Teste antes/depois
- Antes: `/esquadrao` → 404
- Depois: `spec/requests/cartola/{lineups,rankings}_spec.rb` (textos e 301 públicos); `spec/requests/admin/{resources,cartola_settings,scoring_rule_tester}_spec.rb` (URLs novas e 301 do admin)
