# TICKET-0029 — Bolão com 2 faixas configuráveis

- Deps: TICKET-0004, TICKET-0006, TICKET-0010, TICKET-0016
- Skill: [W]tdd, migration
- MCP: [supabase] `execute_sql` só leitura (regras e bolões em produção antes da migração)
- Spec: §7 e §10 (Bolão); [ADR 0004](../adr/0004-bolao-scoring.md)
- Estado anterior: `bolao_scoring_rules(pool_id, kind, points)` com 4 kinds (10/7/5/3); override por bolão linha a linha; sem escopo de campeonato; 4 strategies em `app/services/scoring/strategies/`
- Numeração: o ADR 0003 cita "0029" como Simulador v1; o Simulador entrou como TICKET-0031

## Paths
- `engines/bolao/db/migrate/20261031000031_consolidate_bolao_scoring_rules.rb`, `db/schema.rb`
- `engines/bolao/app/models/bolao/{scoring_rule,pool}.rb`, `engines/bolao/app/services/bolao/calculate_preview_service.rb`, `engines/bolao/lib/bolao.rb`
- `app/jobs/process_match_points_job.rb`, `app/services/scoring/bolao_scorer.rb`, `app/services/bolao/bet_results.rb`
- removidos: `app/services/scoring/strategies/*.rb` (+ specs), `config/initializers/bolao.rb` (`Bolao.scorer`)
- `app/admin/{bolao_scoring_rules,pools,scoring_rule_tester}.rb`, `app/views/admin/scoring_rule_tester/_panels.html.erb`
- `db/seeds/scoring_rules.rb`, `spec/factories/bolao_cartola.rb`
- `docs/spec-v3.md`, `docs/adr/0004-bolao-scoring.md`

## Pronto quando
- `bolao_scoring_rules(championship_id, pool_id, exact_score_points default 10, winner_points default 5)`; colunas `kind` e `points` removidas; dados migrados (`exact_score` → exato; `winner_and_goal_diff`, `winner`, `draw` → `winner_points` com o valor de `winner`)
- Model valida `exact_score_points >= winner_points >= 0` (check `bolao_scoring_rules_bands_ordered` no banco) e um escopo por linha (`bolao_scoring_rules_single_scope`)
- `points_for(prediction_home, prediction_away, actual_home, actual_away)` → `{ points:, result: :exact | :winner | :miss }`; empate certo com placar errado = `:winner`
- `CalculatePreviewService` e `ProcessMatchPointsJob` chamam `points_for` da regra resolvida (bolão → campeonato → global → padrão), numa query
- Admin: "Regras do Bolão" com escopo + "Pontos por placar exato" + "Pontos por vencedor"; form do bolão com "Pontuação própria" (em branco = sem override; checkbox para remover)
- `down` da migration recria as 4 linhas por escopo

## Teste antes/depois
- Antes: palpite 3x2 contra 2x1 = 7; 1x1 contra 0x0 = 3
- Depois: 5 nos dois casos (padrão); `spec/models/bolao/scoring_rule_spec.rb` (4 casos de `points_for`: exato, vencedor, empate, erro, mais escopo e constraints); `spec/services/bolao/calculate_preview_spec.rb` (nome existente mantido; regra do bolão 5/3, empate, regra do campeonato, chamada a `points_for`); `spec/jobs/core/scoring/process_match_points_spec.rb` (10/5/0/0, override do bolão, regra do campeonato); `spec/requests/admin/bolao_scoring_rules_spec.rb` (2 campos, override no form do bolão)
- Migração ensaiada em development: up (4 linhas → 1 global 10/5), rollback (4 linhas 10/5/5/5) e up de novo
