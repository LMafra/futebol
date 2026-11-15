# TICKET-0096 — Lances com minuto e tempo, registrar e desfazer

- Deps: TICKET-0089
- Skill: [W]tdd
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 (grill da partida ao vivo), ADR 0006

## Descrição
- **Só totais:** os scouts eram só totais por jogador e partida (`Cartola::PlayerScore`).
- **Sem minuto:** não havia como registrar "gol aos 32 do 1º tempo".
- **Sem desfazer:** não havia como desfazer o último lance.
- **Sem linha do tempo:** sem lances, a partida ao vivo (TICKET-0097 e TICKET-0098) não tinha linha do tempo para mostrar.

## Ambiente
- Rails 8.1, PostgreSQL 16 (dev em 127.0.0.1:5440), serviços chamados pelas telas do TICKET-0097

## Severidade
Alta: a tela única da partida e a página pública ao vivo dependem dos lances.

## Passos para reproduzir
1. Abrir os scouts de uma partida ao vivo.
2. Tentar registrar um gol com o minuto e o tempo.
3. Tentar desfazer só o último gol lançado.

## Esperado
Cada gol, assistência, cartão ou defesa vira um lance com minuto e tempo, e o "−" desfaz o último lance do jogador naquela estatística.

## Atual
Só dava para editar os totais da planilha.

## Correção
- **`Cartola::ScoutEvent`** (tabela `cartola_scout_events`):
  - campos: partida, jogador, time, `stat` (G, A, DP, DE, CA, CV, GC), `period` (1º tempo, 2º tempo, prorrogação, pênaltis), `minute` (0 a 130), `recorded_by` e `discarded_at`;
  - check constraints no banco e escopo `chronological` (tempo, minuto, ordem de lançamento).
- **`Scouts::RecordEvent`:**
  - salva o lance e, na mesma transação, recalcula os contadores do jogador a partir dos lances mantidos;
  - recalcula SG e pontos da partida com a regra em vigor (`RecordScoutsService.rescore!`) e o placar ao vivo;
  - inicia a partida agendada cujo horário passou, registra `cartola.scout_event_recorded` no `AuditLog` e transmite a partida ao vivo.
- **`Scouts::UndoLast`:**
  - marca `discarded_at` no último lance mantido daquele jogador e estatística; nada é apagado;
  - recalcula na mesma transação e registra `cartola.scout_event_undone`.
- **`Scouts::EventRules`:** as regras da planilha de scouts, valendo também para os lances:
  - partida pontuada ou ainda não iniciada;
  - time fora da partida;
  - DE só para goleiro;
  - limites por estatística (ex.: 1 CV);
  - assistências do time até o número de gols, ao lançar uma assistência e ao desfazer um gol.
- **Backfill** (`Cartola::ScoutEventBackfill`, migração 000059):
  - cria um lance sem minuto para cada unidade dos totais já gravados; os pontos não mudam;
  - rodar de novo não duplica;
  - o `down` remove só os lances sem tempo, minuto e autor.
- **Planilha de scouts:** enquanto existir, mantém os lances iguais aos totais salvos (`Cartola::ScoutEventSync`). Total maior cria lances sem minuto; total menor descarta os mais recentes.

## Evidência
- `spec/services/scouts/record_event_spec.rb`: registrar com minuto, desfazer o último, regras, início automático, partida pontuada
- `spec/data_migrations/scout_event_backfill_spec.rb` e `spec/services/cartola/record_scouts_service_spec.rb` (lances iguais aos totais)
- Backfill no banco de desenvolvimento: 348 lances de gol para 348 gols mantidos

## Pronto quando
- [x] Lance com minuto e tempo; contadores do `PlayerScore` derivados dos lances mantidos
- [x] Desfazer marca `discarded_at` e recalcula na mesma transação
- [x] Backfill sem mudar pontos, com `down`
