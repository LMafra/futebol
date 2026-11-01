# TICKET-0039 — Scouts oficiais do Esquadrão

- Deps: TICKET-0004, TICKET-0010, TICKET-0030
- Skill: [W]tdd
- MCP: —
- Spec: §9; [ADR 0005](../adr/0005-esquadrao-pontuacao-valorizacao.md)
- Estado anterior: nenhum código gravava `Cartola::PlayerScore` (só factory e preview); o placar era digitado na finalização

## Escopo
- Scouts por jogador e partida em `cartola_player_scores`: `team_id`, G, A, DP, DE, CA, CV, GC, `played`, `highlight` e `clean_sheet` (SG, calculado), com checks de limite (G, A, GC e DE 0–20; DP 0–3; CA 0–2; CV 0–1) e um destaque por partida (índice único parcial)
- Regra do Esquadrão ganha `clean_sheet_points`, `penalty_save_points`, `save_points`, `own_goal_penalty`, `played_points` e `highlight_points` (começam em 0); `Cartola::Scorer` soma os termos, e o resultado pode ser negativo
- SG para quem jogou quando o time não sofre gol (gols adversários mais gols contra do próprio time); DE só para goleiros
- `Cartola::RecordScoutsService` com `Cartola::ScoutSheetValidator`: grava só quem jogou ou tem scout, valida limites, assistências do time ≤ gols do time, sem assistência e gol contra na mesma linha, um destaque; deriva o placar (gols do time mais gols contra do adversário), faz broadcast ao vivo e grava AuditLog `cartola.scouts_recorded`
- Tela admin "Scouts da partida" (menu Pontuação): abas Mandante e Visitante, botões − e + com Stimulus (`scouts_controller`), "Jogou" individual e geral, destaque por radio e prévia de Pts; só leitura em `scored`
- Finalização: placar calculado dos scouts, só leitura; bloqueada com "Lance os scouts antes de finalizar" sem PlayerScore

## Paths
- `engines/cartola/db/migrate/20261031000039_add_scouts_to_cartola_player_scores.rb`, `20261031000040_add_scout_columns_to_cartola_scoring_rules.rb`
- `engines/cartola/app/models/cartola/{player_score,scoring_rule}.rb`, `engines/cartola/app/services/cartola/scorer.rb`
- `app/services/cartola/{record_scouts_service,scout_sheet_validator}.rb`, `app/forms/{match_scout_sheet,match_finalization_form}.rb`, `app/services/finalize_match_service.rb`
- `app/admin/{match_scouts,match_finalizer,matches,scoring_rule_tester}.rb`, `app/views/admin/{match_scouts,match_finalizer,scoring_rule_tester}/*`, `app/javascript/{admin.js,controllers/scouts_controller.js}`, `app/views/active_admin/_html_head.html.erb`

## Pronto quando
- Admin lança scouts em partida `live`, `finished` ou `reverted`; o placar ao vivo acompanha
- A finalização usa o placar derivado e não abre sem scouts
- Jogadores da tela carregados com `includes(:team)` e PlayerScores indexados por jogador (sem N+1)

## Teste antes/depois
- Antes: finalizar pedia o placar digitado
- Depois: `spec/services/cartola/scorer_spec.rb`, `spec/services/cartola/record_scouts_service_spec.rb` (participantes, travas, SG, DE, gol contra, broadcast, status recusados, AuditLog), `spec/requests/admin/{match_scouts,match_finalizer,scoring_rule_tester}_spec.rb`, `spec/system/admin_finalizes_match_spec.rb`
