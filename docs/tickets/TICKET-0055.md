# TICKET-0055 — "Como funciona" logo depois dos módulos

- Deps: TICKET-0032 (home)
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: "Como funciona" era a última seção da home, depois do "Ranking de atletas", longe de "Três jeitos de jogar", que apresenta os mesmos modos

## Escopo
- Ordem da home: hero, contadores, "Três jeitos de jogar", "Como funciona", "Jogos de hoje", "Campeonatos" e "Ranking de atletas"

## Paths
- `app/views/home/index.html.erb`, `app/controllers/home_controller.rb` (comentário)

## Pronto quando
- "Como funciona" aparece entre "Três jeitos de jogar" e "Jogos de hoje"

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` checava as seções sem ordem
- Depois: o mesmo spec checa a ordem dos títulos das seções
