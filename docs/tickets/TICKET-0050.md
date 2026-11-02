# TICKET-0050 — Jogos de hoje sem barra de rolagem

- Deps: TICKET-0049
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: a faixa sem fim de "Jogos de hoje" mostrava a barra de rolagem horizontal, que ficava parada no meio durante a volta

## Escopo
- Utilidade `scrollbar-none` em `app/assets/tailwind/application.css` (`scrollbar-width: none` e `::-webkit-scrollbar` escondido)
- A lista de "Jogos de hoje" usa a utilidade e perde o `pb-2` que abria espaço para a barra
- A faixa continua rolando pelas setas, pelo toque, pelo trackpad e por shift + roda

## Paths
- `app/assets/tailwind/application.css`
- `app/views/home/_matches_today.html.erb`

## Pronto quando
- Nenhuma barra de rolagem aparece embaixo da faixa (`scrollbar-width: none`, altura da barra 0)

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` não checava a barra
- Depois: o mesmo spec checa a classe `scrollbar-none` na lista; no navegador, a lista calcula `scrollbar-width: none` e não sobra altura para a barra
