# TICKET-0054 — Top 3 Bolão e Esquadrão no seed dos campeonatos

- Deps: TICKET-0042, TICKET-0052, TICKET-0053
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: os cards dos campeonatos pequenos mostravam "Sem palpites pontuados." e "Sem escalações pontuadas.", porque o seed não criava bolão, escalações nem scouts para eles (os times não tinham elenco). No Brasileirão, o Top 3 Esquadrão tinha só a escalação de `demo1`, ainda sem pontos, e os nomes apareciam todos como "Participante"

## Escopo
- Elenco de 11 para os times dos campeonatos pequenos, pelo mesmo `Seeds.players`, agora num único `insert_all` (as cargas do zero ficam mais rápidas)
- Por campeonato pequeno: um bolão com os 5 usuários demo e palpites até a rodada de hoje; as partidas encerradas recebem scouts e passam pelo job de pontuação (ficam `scored`, como as do Brasileirão); cada usuário escala na última rodada encerrada
- Brasileirão: `demo2`–`demo5` escalam na rodada 6, já pontuada
- Escalações escolhidas entre os jogadores mais baratos do próprio campeonato, com um deslocamento por usuário, compradas pela carteira (`Cartola::WalletService`)
- Cada usuário escala no máximo uma vez por rodada, somando os campeonatos (nos pequenos, a rodada encerrada mais recente ainda livre): reverter a migration que escopou as escalações por campeonato recria o índice único de squad e rodada, e o CI desce essas migrations com o seed carregado
- Usuários demo com nomes (Ana Souza, Bruno Lima, Carla Mendes, Diego Rocha, Elisa Prado); `demo1`–`demo3` autorizam o perfil público, então os rankings mostram nomes e "Participante" lado a lado. Bancos antigos ganham os nomes e o consentimento no próximo `db:seed`, sem trocar nome alterado pelo usuário
- Métodos de escalação do seed em `db/seeds/lineups.rb`

## Paths
- `db/seeds/small_championships.rb`, `db/seeds/demo.rb`, `db/seeds/lineups.rb`, `db/seeds/players.rb`, `db/seeds.rb`
- `docs/OPERATIONS.md`

## Pronto quando
- Todo campeonato, público ou privado, tem Top 3 Bolão e Top 3 Esquadrão com o líder pontuando
- Toda escalação usa só jogadores dos times do próprio campeonato
- Uma segunda carga do seed não cria nada

## Teste antes/depois
- Antes: `spec/seeds_spec.rb` esperava elenco só nos times da Série A e rodadas passadas dos campeonatos pequenos `finished`
- Depois: o mesmo spec checa elenco em todos os times, rodadas passadas `scored`, Top 3 de Bolão e de Esquadrão em todos os campeonatos (só nomes consentidos ou "Participante") e escalações com jogadores do próprio campeonato
