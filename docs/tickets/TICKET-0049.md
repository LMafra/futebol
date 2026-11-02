# TICKET-0049 — Jogos de hoje em faixa sem fim

- Deps: TICKET-0048
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: a faixa horizontal de "Jogos de hoje" parava no primeiro e no último jogo, com os botões desabilitados nas pontas

## Escopo
- Quando os jogos não cabem na largura, o `scroller_controller` põe cópias dos cards antes (uma volta) e depois (duas voltas), escondidas da tecnologia assistiva (`aria-hidden`) e fora da ordem de Tab
- Quando a rolagem assenta fora dos originais (botões, toque, trackpad ou shift + roda), a faixa salta uma volta inteira para o mesmo card entre os originais, sem animação: depois do último jogo vem o primeiro, e "Jogos anteriores" no primeiro leva ao último
- Os botões nunca ficam desabilitados; aparecem só quando a faixa transborda
- As cópias saem ao desconectar e são refeitas ao conectar ou mudar a largura, então o cache do Turbo não acumula cópias
- Sem JS, a faixa é a rolagem horizontal comum do TICKET-0048

## Paths
- `app/javascript/controllers/scroller_controller.js`
- `app/views/home/_matches_today.html.erb`

## Pronto quando
- A partir de qualquer card, "Próximos jogos" e "Jogos anteriores" continuam rolando sem parar
- Leitores de tela veem cada jogo uma vez só

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` checava os botões pelos alvos de habilitar e desabilitar
- Depois: o mesmo spec checa a ação de rolagem da lista e os botões sem `disabled`. A volta foi verificada no navegador: "Jogos anteriores" no início levou aos jogos das 23:00, e cinco cliques em "Próximos jogos" passaram da emenda e continuaram
