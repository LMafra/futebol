# TICKET-0085 — Bug: Escalações do Gestor dão erro 500

- Deps: TICKET-0084
- Skill: [W]tdd
- MCP: —
- Origem: validação manual da leva 0079–0084 (2026-11-12)

## Descrição
A lista de escalações do Esquadrão no Gestor quebra ao abrir: os filtros de campeonato e rodada consultam atributos que o `Cartola::Lineup` não libera para o Ransack (o `Cartola::ApplicationRecord` libera uma lista vazia).

## Ambiente
- Desktop 1440px, Chromium (Playwright), Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23
- Usuário: gestor (`gestor@demo.local`)

## Severidade
Alta: a tela inteira fica inacessível para todo gestor.

## Passos para reproduzir
1. Entrar como gestor.
2. Abrir `/gestor/esquadrao_lineups` (menu Configurações › Escalações).

## Esperado
A lista de escalações abre com os filtros de campeonato e rodada.

## Atual
```
NoMethodError in Gestor::EsquadraoLineups#index
undefined method 'championship_id_eq' for an instance of Ransack::Search
```

## Correção
`Cartola::Lineup` declara `ransackable_attributes` (`championship_id`, `round`) e `ransackable_associations` (`championship`, `squad`), no mesmo padrão de `Bolao::Pool` e `Core::Match`.

## Evidência
`spec/requests/gestor/esquadrao_lineups_spec.rb`: index sem filtro e com `q[championship_id_eq]` + `q[round_eq]` retornam 200 e listam a escalação.

## Pronto quando
- `/gestor/esquadrao_lineups` responde 200 com e sem filtros
- Gate `test` verde
