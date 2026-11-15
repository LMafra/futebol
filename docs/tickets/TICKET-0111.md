# TICKET-0111 — Lances e estatísticas editáveis depois de pontuada

- Deps: TICKET-0110
- Skill: [W]tdd
- MCP: playwright
- Origem: pedido do gestor (2026-11-14): "o gestor tem a liberdade de editar o resultado e as estatísticas depois"

## Descrição
Depois de pontuada, a página da partida ficava só para leitura. Para corrigir um gol, um cartão ou um "Jogou" esquecido, o gestor precisava reverter a pontuação (com motivo), corrigir os lances e finalizar de novo. Eram três passos para uma correção de um clique.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`), partida 387 (Unidos da Vila 3 × 1 Ajax da Brasilândia, "Pontuada")

## Severidade
Média: a correção era possível, mas exigia reverter e finalizar de novo, e o gestor não sentia que tinha o controle da partida.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/matches/387` (situação "Pontuada").
2. Procurar os botões de lance, "−", "Jogou" e "Destaque".

## Esperado
- A partida pontuada continua com os lances, o "−" e "Jogou"/"Destaque".
- Cada alteração refaz o placar a partir dos lances e recalcula os pontos do Bolão e a valorização do Esquadrão na hora; a partida segue "Pontuada".
- O aviso mostra o placar refeito, e a auditoria guarda o placar e a pontuação de antes.

## Atual
A página mostrava "Partida pontuada: os lances ficam só para leitura. Reverta a pontuação para alterá-los.", sem nenhum controle de lance (`docs/checkpoints/ux-audit/before-0111/`). `Scouts::EventRules` recusava lance, desfazer e participação em partida pontuada.

## Correção
- **`Scouts::Rescore`**, chamado por `Scouts::RecordEvent`, `Scouts::UndoLast` e `Scouts::MarkParticipation` dentro do mesmo lock, depois de recontar as estatísticas. Numa partida pontuada:
  - `MatchPoints.unscore!` descarta os pontos do Bolão e devolve os valores do Esquadrão da pontuação atual;
  - o placar volta a ser o dos lances (`Cartola::PlayerScore.score_for`);
  - `MatchPoints.score!` pontua de novo sob um `scoring_token` novo;
  - a auditoria `rescore` guarda o placar e o token novos e, em `before`, o placar e o token anteriores.
- Partidas que não estão pontuadas seguem como antes, sem pontuar.
- **`Scouts::EventRules`:** a partida pontuada deixou de ser recusada. Continua recusada a partida "Agendada" antes do horário.
- **Página da partida (Admin e Gestor):**
  - os lances, o "−" e "Jogou"/"Destaque" aparecem também na partida pontuada;
  - a nota "Partida pontuada: cada lance, "Jogou" ou "Destaque" alterado aqui refaz o placar e os pontos do Bolão e do Esquadrão na hora." substitui o aviso de só leitura;
  - os avisos terminam com "Placar e pontos refeitos: 3 × 2.";
  - a partida pontuada também recebe a atualização ao vivo da página pública.
- A ficha de estatísticas em lote (`Cartola::RecordScoutsService`, sem tela; só seeds e specs) continua recusando partida pontuada.

## Evidência
- Specs:
  - `spec/services/scouts/rescore_spec.rb`: lance numa partida pontuada refaz o placar (1 × 0 para 1 × 1) e os pontos do Bolão sob um token novo, descartando os antigos; auditoria com o antes e o depois; desfazer devolve os 10 pontos do palpite exato; "Jogou" reprecifica só sob o token novo; partida não pontuada fica sem pontos;
  - `spec/requests/admin/match_board_spec.rb`: a partida pontuada mostra a nota e o diálogo de lance, sem a barra de finalizar; o lance leva a 1 × 1 com "Placar e pontos refeitos: 1 × 1.";
  - `spec/services/scouts/record_event_spec.rb`: a partida agendada antes do horário continua recusada.
- Navegador (`tmp/pw/edit0111.js`, partida 387):
  - Gestor: gol do visitante, "Lance registrado: Gol · Felipe Santos · 1º tempo. Placar e pontos refeitos: 3 × 2." (situação "Pontuada"); o "−" desfez e voltou a 3 × 1;
  - Admin: "Destaque" do goleiro, "Placar e pontos refeitos: 3 × 1.";
  - cada alteração gravou um `rescore` com o placar e o token anteriores.
- Screenshots: `docs/checkpoints/ux-audit/before-0111/` e `after-0111/` (página do Gestor e do Admin, gol registrado na partida pontuada, Destaque marcado pelo Admin).

## Pronto quando
- [x] Lances, "−" e "Jogou"/"Destaque" disponíveis na partida pontuada (Admin e Gestor)
- [x] Cada alteração refaz o placar e recalcula o Bolão e a valorização do Esquadrão na hora, sem reverter
- [x] Auditoria `rescore` com o placar e a pontuação anteriores
