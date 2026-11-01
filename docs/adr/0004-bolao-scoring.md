# ADR 0004 — Bolão: pontuação em 2 faixas configuráveis

- Status: aceito · Data: 2026-11-01
- Fonte: TICKET-0029 (pedido do usuário: "placar exato = X; vencedor/empate correto com placar errado = Y; erro = 0; X e Y definidos pelo admin por campeonato, com override opcional por pool")
- Relação: substitui a regra 10/7/5/3/0 da spec v3 §7 e do TICKET-0016; não altera os ADRs 0001–0003

## 1. Problema
A regra tinha 4 faixas (placar exato 10, vencedor + saldo 7, vencedor 5, empate não exato 3), gravadas como uma linha por `kind` em `bolao_scoring_rules`, com override por bolão linha a linha. A regra de produto definida tem só duas faixas e é configurada por campeonato, o que o modelo antigo não representava: não havia escopo de campeonato, e um override parcial (só `exact_score`, por exemplo) misturava faixas de níveis diferentes.

## 2. Decisão
- Duas faixas: `exact_score_points` (padrão 10) e `winner_points` (padrão 5). Acertar o vencedor ou o empate com placar errado vale `winner_points`; o resto vale 0. Empate não é faixa separada, e acertar o saldo não vale mais que acertar só o vencedor.
- Uma linha por escopo em `bolao_scoring_rules`: global (sem campeonato nem bolão), campeonato (`championship_id`) ou bolão (`pool_id`). A linha mais específica vence por inteiro: bolão → campeonato → global → padrão 10/5.
- Invariante no model e no banco: `exact_score_points >= winner_points >= 0`; uma linha não pode ter campeonato e bolão ao mesmo tempo.
- Cálculo puro em `Bolao::ScoringRule#points_for(prediction_home, prediction_away, actual_home, actual_away)`, que devolve `{ points:, result: :exact | :winner | :miss }`. O preview (`Bolao::CalculatePreviewService`), o `ProcessMatchPointsJob`, o `Scoring::Engine` (via `Scoring::BolaoScorer`), o testador de regras e a tela de palpites leem desse único lugar. As 4 strategies (`ExactScore`, `WinnerAndGoalDiff`, `Winner`, `Draw`) saem do código.

## 3. Migração de dados
`20261031000031_consolidate_bolao_scoring_rules` agrupa as linhas por escopo. `exact_score` vira `exact_score_points`; `winner` vira `winner_points`; as faixas 7 (`winner_and_goal_diff`) e 3 (`draw`) passam a pontuar como `winner_points`. Faixa ausente num bolão herda a global e, na falta dela, o padrão. Se `winner > exact`, `winner_points` é limitado a `exact_score_points`. O `down` recria as 4 linhas por escopo a partir das 2 colunas (regras de campeonato são descartadas). Produção (Supabase, consultado em 2026-11-01) tinha só a regra global 10/7/5/3 e 0 bolões: vira uma linha global 10/5.

## 4. Alternativas
| | A — 2 colunas, 1 linha por escopo | B — manter `kind`, só com 2 kinds | C — colunas em `core_championships` e `bolao_pools` |
|---|---|---|---|
| escopo de campeonato | coluna `championship_id` | precisaria da mesma coluna | nativo |
| invariante exato ≥ vencedor | check na mesma linha | exige comparar linhas | check na mesma linha, mas em 2 tabelas |
| dependência entre engines | Bolão → Core (já existe) | idem | Core passaria a conhecer o Bolão (proibido pelo ADR 0001) |
| custo | 1 migration + model | migration + lógica de override parcial | 2 migrations e regra espalhada |

A foi escolhida: mantém a regra no Bolão, impõe a invariante no banco e resolve o escopo numa query.

## 5. Consequências
- Pontos já gravados (`bolao_prediction_scores`) não são recalculados; partidas pontuadas com 10/7/5/3 só mudam se forem revertidas e re-pontuadas.
- Palpites que acertavam o saldo (antes 7) ou o empate (antes 3) passam a valer `winner_points`.
- O form do bolão no admin expõe a pontuação própria (em branco = usa a regra do campeonato).
