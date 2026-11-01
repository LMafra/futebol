# TICKET-0042 — Jogos de hoje com vários campeonatos e campeonatos pequenos no seed

- Deps: TICKET-0035, TICKET-0041
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública); seeds de demonstração
- Estado anterior: o seed criava só o Brasileirão, então "Jogos de hoje" quase sempre ficava vazio, e os cards não diziam de qual campeonato era cada jogo

## Escopo
- "Jogos de hoje" agrupa os jogos por campeonato: cada grupo tem o nome do campeonato (link para a página pública) e a contagem de jogos, na ordem do primeiro horário do dia. O campeonato vem no `includes` da consulta, sem N+1
- Seed local (development/test, como a demo): 5 campeonatos públicos fictícios de 6, 8, 10, 12 e 6 times (`db/seeds/small_championships.yml`), com 42 times novos e turno único (169 partidas)
- A rodada do meio de cada campeonato cai hoje, com jogos das 10:00 às 20:00 (fuso do app, o mesmo do filtro da home); rodadas anteriores encerradas com placar, posteriores agendadas. Na rodada de hoje, jogos que começaram há mais de 2 horas ficam encerrados e os que começaram há menos de 2 horas, ao vivo
- Rodar o seed em outro dia desloca o calendário desses campeonatos em dias inteiros, para a rodada do meio voltar a ser hoje. Os status só avançam: um jogo encerrado num seed anterior continua encerrado mesmo que o deslocamento o leve para mais tarde no dia
- Os times novos não têm elenco: o seletor do Esquadrão lista todos os jogadores do banco, não só os do campeonato, e 462 atletas amadores poluiriam a escalação do Brasileirão

## Paths
- `db/seeds.rb`, `db/seeds/small_championships.{rb,yml}`
- `app/controllers/home_controller.rb`, `app/views/home/_matches_today.html.erb`

## Pronto quando
- A home local mostra "Jogos de hoje" com pelo menos 5 campeonatos, cada um no seu grupo
- Rodar o seed duas vezes não cria nada novo; rodar num dia seguinte traz a rodada do meio para hoje

## Teste antes/depois
- Antes: `spec/seeds_spec.rb` esperava um único campeonato e 20 times no banco
- Depois: `spec/seeds_spec.rb` (Brasileirão isolado dos demais, 5+ campeonatos de 6 a 12 times em turno único, rodada do meio hoje, calendário deslocado num dia seguinte, jogadores só nos times da Série A); `spec/requests/home_spec.rb` (jogos de hoje agrupados por campeonato, com link e contagem)
