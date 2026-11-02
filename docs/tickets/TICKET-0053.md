# TICKET-0053 — Esquadrão só com jogadores do campeonato

- Deps: TICKET-0025, TICKET-0040
- Skill: [W]tdd
- MCP: —
- Spec: §2 (Cartola `lineups`)
- Estado anterior: o seletor da escalação listava todos os jogadores do banco, de qualquer time, e o salvamento aceitava qualquer id de jogador. Com elenco nos times dos campeonatos pequenos (TICKET-0054), a escalação do Brasileirão ofereceria jogadores de fora do campeonato

## Escopo
- `Core::Championship#teams`: os times com ao menos uma partida no campeonato, como mandante ou visitante
- O seletor da escalação lista os jogadores desses times, mais os que já estão na escalação, para uma escalação antiga continuar editável
- O salvamento segue a mesma regra: id de jogador de fora é ignorado

## Paths
- `engines/core/app/models/core/championship.rb`
- `app/controllers/cartola/lineups_controller.rb`

## Pronto quando
- O formulário de escalação não mostra jogador de time sem partida no campeonato
- Enviar um jogador de fora salva a escalação sem ele

## Teste antes/depois
- Antes: `spec/requests/cartola/lineups_spec.rb` escalava jogadores de times soltos
- Depois: o mesmo spec escala jogadores de um time do campeonato e checa o seletor e o jogador de fora ignorado; `spec/models/core/championship_spec.rb` checa `#teams`
