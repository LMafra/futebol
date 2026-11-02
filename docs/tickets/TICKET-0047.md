# TICKET-0047 — Classificação no card de campeonato da home

- Deps: TICKET-0035, TICKET-0046
- Skill: [W]tdd
- MCP: —
- Spec: §10 (home pública)
- Estado anterior: o card de cada campeonato da home mostrava só o Top 3 do Bolão e o Top 3 do Esquadrão

## Escopo
- O card abre com a classificação: as 4 primeiras posições da tabela real (só partidas encerradas, mesma ordem do Simulador), com time e pontos, e o link "Tabela completa" para a aba de times da página do campeonato
- Sem partida encerrada, o bloco diz "Nenhum jogo encerrado ainda."
- O Top 3 do Bolão e o Top 3 do Esquadrão vêm depois, separados por uma linha
- `Core::ChampionshipStandingsService` monta as classificações de todos os campeonatos em duas consultas (partidas e nomes dos times), sem N+1

## Paths
- `app/services/core/championship_standings_service.rb`
- `app/controllers/home_controller.rb`
- `app/views/home/index.html.erb`, `app/views/home/_championships.html.erb`

## Pronto quando
- Em cada card, a ordem dos blocos é classificação, Top 3 do Bolão, Top 3 do Esquadrão
- Os líderes saem só das partidas encerradas (uma partida ao vivo não conta)

## Teste antes/depois
- Antes: `spec/requests/home_spec.rb` não tinha classificação no card
- Depois: o mesmo spec checa a ordem dos blocos, os 4 líderes com pontos e desempate, o link "Tabela completa" e o estado vazio
