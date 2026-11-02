# TICKET-0046 — Scroll snap da home por proximidade

- Deps: TICKET-0043
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: a home tinha scroll snap obrigatório (`snap-mandatory`): toda rolagem terminava encaixada numa seção

## Escopo
- O `scroll_snap_controller` passa a aplicar `snap-y snap-proximity` no `<html>`: a página só encaixa quando a rolagem para perto do início de uma seção, do cabeçalho ou do rodapé; no meio de uma seção longa, fica onde o usuário parou
- O resto do TICKET-0043 continua: snap só na home, ligado e desligado pelo controller por causa do Turbo

## Paths
- `app/javascript/controllers/scroll_snap_controller.js`

## Pronto quando
- Na home, `scroll-snap-type` do `<html>` é `y proximity`; fora dela, `none`

## Teste antes/depois
- Antes: `spec/system/visitor_simulates_championship_spec.rb` checava `snap-mandatory`
- Depois: o mesmo spec checa `snap-proximity` na home e a ausência dele no simulador (roda com Chrome)
