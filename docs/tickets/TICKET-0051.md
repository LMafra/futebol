# TICKET-0051 — Jogos de hoje: cards inteiros e passo de um card

- Deps: TICKET-0050
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: o último card visível da faixa aparecia cortado, e as setas rolavam uma largura inteira de faixa por clique

## Escopo
- Os cards ocupam uma fração exata da faixa: 1 no celular, 2 em `sm`, 3 em `md` e 4 em `lg`. O espaço entre eles virou o `pr-3` de cada item, e a lista avança `-mr-3` para a direita, então um número inteiro de cards preenche a largura e o último termina alinhado com a linha do título
- O card passou para um `div` dentro do `li`, que só carrega a largura e o espaço
- "Próximos jogos" e "Jogos anteriores" andam um card por clique; a faixa continua sem fim (TICKET-0049)

## Paths
- `app/views/home/_matches_today.html.erb`
- `app/javascript/controllers/scroller_controller.js`

## Pronto quando
- Nenhum card visível aparece cortado
- Cada clique numa seta muda o primeiro card visível em uma posição

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` não checava a largura dos itens
- Depois: o mesmo spec checa as frações por tamanho de tela, o `pr-3` dos itens e o `-mr-3` da lista. No navegador, a 1248px de faixa, os 4 cards terminam em 1326px, igual à linha do título, e cada clique anda 315px (um card)
