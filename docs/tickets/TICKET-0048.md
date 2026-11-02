# TICKET-0048 — Jogos de hoje numa faixa horizontal única

- Deps: TICKET-0042
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: "Jogos de hoje" tinha um bloco por campeonato, cada um com sua faixa; com muitos campeonatos, a seção crescia sem limite na vertical

## Escopo
- Uma faixa só, com rolagem horizontal e snap por card (`snap-x snap-mandatory`), com todos os jogos de hoje em ordem de horário
- Cada card traz o nome do campeonato (link para a página dele), status, horário e placar
- O cabeçalho da seção mostra o total de jogos e os botões "Jogos anteriores" e "Próximos jogos" (`scroller_controller`), que rolam uma largura visível por clique; aparecem só quando a faixa transborda. Sem JS, a faixa rola por toque, trackpad ou shift + roda
- Largura dos cards: 3/4 da faixa no celular, 1/3 em `sm` e 1/4 em `lg`, para o card seguinte aparecer cortado e indicar a rolagem

## Paths
- `app/views/home/_matches_today.html.erb`
- `app/javascript/controllers/scroller_controller.js`

## Pronto quando
- A seção tem altura de um card, com qualquer número de campeonatos
- Cada card diz de que campeonato é o jogo

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` checava um grupo por campeonato
- Depois: o mesmo spec checa a faixa única, a ordem por horário, o campeonato em cada card, o total e os botões
