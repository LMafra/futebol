# Handoff — Fase 4 (Tickets) — ok

## Decisões
- 13 tickets a→m = TICKET-0001..0013; deps sempre para trás (topológico)
- Índice: `docs/tickets/INDEX.md`
- Scaffold (Fase 5) deve referenciar nas migrations TODO:
  - core (teams, championships, users, matches, audit_logs, csv_imports) → TICKET-0002
  - bolao (pools, predictions, prediction_scores) → TICKET-0004 (prediction_scores) / TICKET-0002
  - cartola (squads, lineups, player_scores) → TICKET-0007
- Stubs NotImplementedError: Scoring::Engine/ProcessMatchPointsJob (0004), RevertMatchPointsService/Job (0005), Bolao preview (0006), Cartola preview (0007), BroadcastUpdateService (0008), ProcessCsvImportJob (0009), policies (0010), components (0011)

## Próximo
- TICKET-0001 (Rails + engines + packwerk) — Fase 5 cobre esqueleto sem gems de domínio

## Avisos
- to-tickets indisponível; herda warning Fase 1
