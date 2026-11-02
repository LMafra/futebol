# TICKET-0052 — Scouts no seed demo

- Deps: TICKET-0032 (home), TICKET-0042
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: o seed não lançava scouts, então o "Ranking de atletas" da home aparecia vazio ("Nenhum scout lançado ainda.") e não dava para validar a interface

## Escopo
- `db/seeds/scouts.rb`: scouts de cada partida finalizada do demo (rodadas 1–4 e 6 do Brasileirão), gravados antes do job de pontuação, então os preços dos jogadores também variam
- Os 11 de cada lado jogam; os gols do time vão para atacantes e meias em rodízio, um gol sim, um não com assistência; o goleiro faz defesas; um jogador de linha leva amarelo; o maior pontuador da partida é o destaque
- Pontos pelo `Cartola::Scorer` com a regra em vigor, como o `Cartola::RecordScoutsService` daria. Gravação direta porque o serviço recusa partidas já pontuadas, e bancos semeados antes só têm partidas pontuadas
- Idempotente: partida que já tem scouts fica como está; bancos antigos ganham os scouts no próximo `db:seed`
- O resumo do `db:seed` passa a contar `Cartola::PlayerScore`

## Paths
- `db/seeds/scouts.rb`, `db/seeds/demo.rb`, `db/seeds.rb`
- `docs/OPERATIONS.md`

## Pronto quando
- A home mostra o "Ranking de atletas" com 10 jogadores, com J, G, A e Pts
- Em cada partida, os gols dos scouts batem com o placar, há um destaque e nenhuma assistência sobra

## Teste antes/depois
- Antes: `spec/seeds_spec.rb` não tinha scouts
- Depois: o mesmo spec checa 22 scouts por partida finalizada, o placar pelos scouts, um destaque, assistências ≤ gols, defesas só de goleiro e o top 10 de atletas ordenado, com gols
