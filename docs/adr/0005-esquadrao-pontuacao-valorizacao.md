# ADR 0005 — Esquadrão: scouts, capitão e valorização por regressão à média

- Status: aceito · Data: 2026-11-01
- Fonte: TICKET-0039 (scouts oficiais e PlayerScore) e TICKET-0040 (capitão e valorização), a partir do pedido do usuário: "G, A, SG, DP, DE (só goleiro), CA, CV, GC; capitão com pontuação dobrada, positiva ou negativa; valorização por regressão à média" e da dica em Python enviada com ele
- Relação: substitui a valorização de ±20% sobre a média da partida (`Cartola::ValueUpdateJob`, TICKET-0031); não altera os ADRs 0001–0004

## 1. Problema
O `Cartola::PlayerScore` guardava só gols, assistências e cartões, digitados sem relação com o placar. Não havia SG, defesas, gol contra nem participação, e o placar da finalização era digitado à parte. A escalação não tinha capitão. O preço do jogador subia ou descia até 20% conforme a média da partida, o que premiava quem jogava em partidas fracas e não tinha piso nem memória do preço inicial.

## 2. Decisão
### Scouts
- Uma linha mantida (`kept`) por jogador e partida, só para quem participou: "Jogou", "Destaque" ou ao menos um scout. Lançada no admin "Scouts da partida" (`Cartola::RecordScoutsService`), com contadores + e −, aba por time e prévia dos pontos no navegador.
- Scouts e limites (iguais aos checks do banco): G 0–20, A 0–20, DP 0–3, DE 0–20 (só goleiro), CA 0–2, CV 0–1, GC 0–20. SG é derivado: quem jogou e cujo time não sofreu gol.
- Placar = gols do time + gols contra do adversário. Assistências de um time não passam do número de gols dele. No máximo um destaque por partida.
- Pontos = Σ bônus (G, A, SG, DP, DE) − Σ penalidades (CA, CV, GC) + Jogou + Destaque, com os pesos de `Cartola::ScoringRule` definidos pelo admin (padrão das colunas novas: 0).
- A finalização usa o placar dos scouts (o admin só confirma digitando "HxA") e recalcula os pontos com a regra em vigor. Uma partida pontuada não aceita scouts até ser revertida.

### Capitão
- Obrigatório e único em toda escalação com jogadores (validação no model e índice único parcial `lineup_id WHERE captain`).
- No ranking, `Cartola::RankingsService::POINTS_SUM` multiplica os pontos do capitão por 2, inclusive os negativos. O capitão que não jogou não tem PlayerScore e não dá bônus.

### Valorização (`Cartola::Valuation`)
Função pura, com as constantes num só lugar:

| constante | valor |
|---|---|
| `EXPECTED_RATE` | 0.45 |
| `HISTORY_RATE` | 0.25 |
| `DAMPING` | 4 |
| `MAX_VARIATION` | C$ 5 |
| `MIN_PRICE` | C$ 0.50 |

```
historical = (atual − inicial) × HISTORY_RATE × peso
peso       = 0 no 1º jogo do jogador no campeonato, 0.5 no 2º e no 3º, 1 do 4º em diante
expected   = atual × EXPECTED_RATE + historical
variação   = clamp((pontos − expected) / DAMPING, −MAX_VARIATION, +MAX_VARIATION)
novo preço = max(atual + variação, MIN_PRICE), arredondado em 2 casas
```

- `inicial` é `Core::Player#base_value_in(campeonato)`; `atual` é o `Cartola::PlayerValue` (ou o inicial, antes da primeira valorização).
- A contagem de jogos é por jogador: jogos já valorizados no campeonato + o atual. Quem estreia tarde cai sozinho na regra do 1º jogo.
- Só quem jogou (`played`) é reprecificado, com os próprios pontos, sem a dobra de capitão (a dobra é da escalação, não do jogador).
- `cartola_player_value_histories` guarda `expected_score`, `games_played` e `average_score` (a média do jogador no campeonato). A idempotência por `scoring_token` e o `PlayerValue.revert!` do Reversal continuam iguais.

## 3. Divergências da dica
- O texto da dica fala em 0.5 para o esperado e 0.2 para o histórico; o código dela usa 0.45 e 0.25. Valem as do código, que reproduzem o Cenário A.
- O script aplicava o piso de C$ 0.50 antes da trava de ±C$ 5. A ordem aqui é a do texto: primeiro a trava sobre a variação, depois o piso sobre o preço.
- Cenário A (C$ 5, inicial 5, 8 pontos, 1º jogo): esperado 2.25, variação +1.4375, novo preço C$ 6.44, como na dica.
- Cenário B (C$ 20, inicial 15, 5 pontos, a partir do 4º jogo): histórico 1.25, esperado 10.25, variação −1.3125, novo preço **C$ 18.69**. A dica dizia C$ 18.44, valor que não sai da própria fórmula.

## 4. Alternativas
| | A — regressão à média por jogador | B — ±20% sobre a média da partida (anterior) | C — oferta e demanda (escalações) |
|---|---|---|---|
| referência | o próprio preço e o preço inicial | os outros jogadores da partida | quantos técnicos escalam o jogador |
| piso e teto | C$ 0.50 e ±C$ 5 por jogo | só ±20% | depende de volume |
| dados necessários | PlayerScore + histórico | PlayerScore | escalações em volume, que ainda não existem |

A foi escolhida: é a regra pedida, previsível para o técnico e testável sem volume de usuários.

## 5. Consequências
- Pontos e preços já gravados não são recalculados (produção tinha 0 escalações e 0 históricos de valor).
- Partidas sem scouts não podem ser finalizadas pelo admin; os jogadores sem "Jogou" mantêm o preço.
- Oferta e demanda fica como pendência futura (registrada no STATUS), sem ticket numerado.
