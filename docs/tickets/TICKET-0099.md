# TICKET-0099 — Participantes › Bolão: membros, palpites, ranking e correções com motivo

- Deps: TICKET-0093, TICKET-0095, TICKET-0102
- Skill: [W]tdd
- MCP: playwright (Gestor em 390px)
- Origem: rodada de ajustes de 2026-11-12 (fase 5, participantes), ADR 0006

## Descrição
- **Página sem participantes:** no Gestor, a página do bolão mostrava só o código e quantas pessoas tinham entrado. No Admin, era a página padrão do ActiveAdmin.
- **Sem ranking nem palpites:** o organizador não via o ranking nem os palpites de cada participante.
- **Sem correção:** não havia como corrigir um palpite digitado errado. Também não havia como tirar alguém do bolão, a não ser direto no banco e sem registro.

## Ambiente
- Rails 8.1, ActiveAdmin 4 (`/admin/pools/:id` e `/gestor/pools/:id`)
- Chromium 1208 (Playwright) em 390×844, como gestor@demo.local

## Severidade
Média: o organizador não conseguia acompanhar o próprio bolão nem resolver os pedidos dos participantes.

## Passos para reproduzir
1. Entrar como gestor e abrir Participantes › Bolões › um bolão com participantes.
2. Procurar o ranking e os palpites de um participante.
3. Tentar corrigir um palpite ou remover alguém.

## Esperado
- Ranking e participantes com os palpites de cada um.
- Corrigir um palpite e remover um participante, sempre com motivo na auditoria.
- Se a partida já foi pontuada, os pontos são recalculados.

## Atual
Só o código do bolão e o número de participantes.

## Correção
- **Página do bolão** (`AdminPoolParticipants`, `admin/pool_participants/*`, `PoolParticipants`), igual no Admin e no Gestor:
  - **Ranking:** pontos dos palpites mantidos. Empate divide a posição ("1, 1, 3"), com o número de palpites.
  - **Participantes:** lista com detalhe (`Ui::CollectionComponent`, modo `master_detail`, `?membro=ID`).
  - **Detalhe do participante:** os palpites por partida, com o placar e os pontos de cada um.
- **Corrigir palpite** (`Bolao::PredictionCorrection`, diálogo `correction`):
  - novos placares e motivo obrigatório;
  - vale mesmo depois do início da partida (contexto `:correction`, fora da trava de palpites);
  - se a partida já foi pontuada, recalcula os pontos com a regra do bolão, no mesmo token de pontuação;
  - `AuditLog` `bolao.prediction_corrected` com antes, depois, motivo e pontos.
- **Remover do bolão** (`Bolao::MemberRemoval`, diálogo `removal`):
  - motivo obrigatório;
  - os palpites e os pontos do participante neste bolão são descartados (saem do ranking e ficam no histórico);
  - `AuditLog` `bolao.member_removed`.
- **Quem pode** (`correct_prediction?` e `remove_member?`):
  - no Admin, o Admin;
  - no Gestor, quem gerencia o campeonato do bolão;
  - bolões de outros campeonatos ficam fora do escopo do Gestor.
- **Diálogos guardam o estado da página:**
  - `return_to` leva a query da página, sem os parâmetros do próprio diálogo;
  - com erro, `?modal=` entra na query que já existia, então o diálogo reabre no mesmo participante.

## Evidência
- `spec/requests/admin/pool_participants_spec.rb`:
  - ranking com empate;
  - detalhe do participante;
  - correção com recálculo e auditoria;
  - sem motivo, volta ao diálogo com `?membro=`;
  - remoção descarta palpites e pontos;
  - o Gestor corrige no seu bolão e não alcança o de outro gestor.
- Playwright (`tmp/pw/pool0099.js`, 390px):
  - ranking e detalhe do participante, sem rolagem lateral;
  - "Corrigir" abre o diálogo com foco no motivo;
  - enviar sem motivo reabre o diálogo no mesmo participante, com o alerta e o foco no motivo.

## Pronto quando
- [x] Membros por bolão, palpites por partida e ranking
- [x] Editar palpite e remover membro, com motivo + `AuditLog`
- [x] Recalcula se a partida já foi pontuada
