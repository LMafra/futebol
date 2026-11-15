# TICKET-0110 — Finalizar a partida pontua na hora, com confirmação em um clique

- Deps: TICKET-0109
- Skill: [W]tdd
- MCP: playwright
- Origem: pedido do gestor (2026-11-14): "a finalização da partida demora para realizar a pontuação; o gestor precisa ter controle total"

## Descrição
Ao finalizar, a partida ia para "Encerrada" e a pontuação (Bolão e valorização do Esquadrão) ficava numa fila (`ProcessMatchPointsJob`, depois `Cartola::ValueUpdateJob`). Sem um worker do Solid Queue rodando, a partida ficava parada em "Encerrada", e o gestor não tinha como pontuar por conta própria. O diálogo ainda pedia para redigitar o placar ("2x1"), que já vem dos lances.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`)
- Desenvolvimento só com o Puma (`bin/rails s`), sem worker do Solid Queue

## Severidade
Alta: a partida finalizada não pontuava sem o worker, e o gestor não tinha como destravar uma partida parada em "Encerrada".

## Passos para reproduzir
1. Entrar como admin, abrir uma partida "Ao vivo" com lances e clicar em "Finalizar partida".
2. Digitar o placar no campo "Confirme o placar" e confirmar.
3. Ver a situação da partida e o painel do Gestor (`/gestor`).
4. Abrir uma partida que ficou em "Encerrada" (`/gestor/matches/395`).

## Esperado
- O diálogo mostra o placar dos lances e confirma em um clique ("Finalizar e pontuar"), sem redigitar.
- O mesmo clique encerra a partida e calcula os pontos do Bolão e a valorização do Esquadrão: a partida vai direto para "Pontuada".
- A reversão também desfaz os pontos na hora.
- Uma partida "Encerrada" (parada na fila antiga) ou "Revertida" mostra "Finalizar partida" e pontua de novo.

## Atual
- O diálogo exigia "Confirme o placar, ex.: 2x1 (obrigatório)" e avisava que a pontuação seria enfileirada (`docs/checkpoints/ux-audit/before-0110/admin-finalizar-*.png`).
- A partida ficava em "Encerrada" e o painel do Gestor mostrava "Pontuando", sem ação.
- A partida 395 estava em "Encerrada" sem botão para finalizar nem pontuar (`gestor-partida-encerrada-*.png`).

## Correção
- **`MatchPoints`** (`app/services/match_points.rb`), chamado dentro do lock da partida:
  - `score!` grava os pontos de cada palpite do Bolão sob um `scoring_token` novo, leva a partida para "Pontuada" e roda a valorização do Esquadrão;
  - `unscore!` leva a partida para "Revertida", descarta os pontos daquele token e devolve os valores dos jogadores.
- **`Cartola::ValueUpdate`:** o corpo de `Cartola::ValueUpdateJob` virou um serviço chamado direto. O job e o `ProcessMatchPointsJob` ficam como invólucros finos para os jobs que já estavam na fila (só pontuam partida que ainda espera a pontuação).
- **`FinalizeMatchService`:**
  - aceita partidas "Ao vivo", "Encerrada" e "Revertida" (e "Agendada" com o início já passado);
  - recalcula as estatísticas, grava o placar dos lances, encerra e pontua na mesma transação;
  - a auditoria `finalize` guarda o placar e o `scoring_token`.
- **`MatchFinalizationForm`:** sem o campo de confirmação, o placar vem dos lances. Os erros (sem lances, partida já pontuada) aparecem como aviso na página da partida, com a situação em português.
- **`RevertMatchPointsService` / `MatchReversalForm`:** a reversão é síncrona. O aviso diz "Pontuação revertida e registrada na auditoria. Finalize a partida de novo para pontuar."
- **Diálogo "Finalizar partida":** mostra o placar dos lances, explica que os pontos do Bolão e do Esquadrão são calculados na hora e confirma em "Finalizar e pontuar".
- **Painéis:**
  - no Gestor, "Encerrada" e "Revertida" têm o próximo passo "Finalizar partida" (o "Pontuando" saiu);
  - no Admin, "Pontuação pendente" e o escopo "Encerradas sem pontuação" incluem as revertidas, e a tabela de pendentes tem "Situação" e o atalho "Finalizar".
- `docs/spec.md` e `docs/spec-v3.md` ainda descrevem o `ProcessMatchPointsJob` como o caminho da pontuação. Ficaram como estão, como registro do desenho original.

## Evidência
- Specs:
  - `spec/services/finalize_match_service_spec.rb`: pontua na hora (pontos do Bolão e histórico de valorização sob o mesmo token), nenhum job enfileirado, refinaliza "Encerrada" e "Revertida", auditoria com o token;
  - `spec/jobs/core/scoring/process_match_points_spec.rb` e `spec/jobs/cartola/value_update_job_spec.rb`: os invólucros pontuam só a partida que espera e desfazem tudo se a valorização falhar;
  - `spec/requests/admin/match_board_spec.rb` e `spec/requests/gestor/scoring_spec.rb`: diálogo sem campo, um clique leva a "Pontuada" com 2 × 1;
  - `spec/requests/admin/match_reversal_spec.rb`: reversão síncrona;
  - `spec/requests/gestor/dashboard_spec.rb` e `spec/services/gestor/match_queue_spec.rb`: "Encerrada" tem "Finalizar partida";
  - `spec/requests/admin/consistency_spec.rb`: partida sem lances explica o motivo;
  - `spec/system/admin_finalizes_match_spec.rb` (Chromium): lances na página, "Finalizar e pontuar", palpites pontuados.
- Navegador (`tmp/pw/finalize0110.js`, só o Puma, sem worker):
  - Admin, partida 41 ("Ao vivo"): diálogo com "Athletico Paranaense 1 × 0 Remo", um clique, "Partida finalizada em 1 × 0 e pontuada.", situação "Pontuada" (cerca de 1 s);
  - Gestor, partida 395 (parada em "Encerrada"): "Finalizar partida" voltou a aparecer, "Partida finalizada em 2 × 1 e pontuada.", situação "Pontuada" (cerca de 1 s).
- Screenshots: `docs/checkpoints/ux-audit/before-0110/` e `after-0110/` (diálogo do Admin, painel do Admin, painel do Gestor, partida do Gestor antes e depois de finalizar, partida do Admin pontuada).

## Pronto quando
- [x] Finalizar calcula o Bolão e a valorização do Esquadrão no próprio clique, sem fila
- [x] Confirmação em um clique com o placar dos lances, sem redigitar
- [x] Reversão desfaz os pontos na hora
- [x] Partida "Encerrada" ou "Revertida" pode ser finalizada de novo pelo Admin e pelo Gestor
