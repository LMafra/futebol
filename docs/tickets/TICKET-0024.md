# TICKET-0024 — Bolão: palpites

- Deps: TICKET-0023, TICKET-0006
- Skill: implement-spec (indisponível localmente → [W]tdd)
- MCP: —
- Spec: §2 (`predictions` com `discarded_at`), §5 (`PredictionFormComponent`), §7 (`Bolao::CalculatePreviewService`, regra 10/7/5/3/0)
- Decisão: "palpite" persiste em `Bolao::Prediction` (`home_guess`, `away_guess`; unique kept `(pool_id, user_id, match_id)`); não há model `Bet` novo

## Paths
- `app/controllers/bolao/bets_controller.rb`, `config/routes.rb` (`resources :bets, only: %i[index create update]` aninhado em `pools`)
- `app/policies/bolao/bet_policy.rb` (registro `Bolao::Prediction`; `policy_class: Bolao::BetPolicy`)
- `app/components/bolao/{match_list,my_bets}_component.{rb,html.erb}`, `app/javascript/controllers/countdown_controller.js`
- `spec/requests/bolao/bets_spec.rb`, `spec/policies/bolao/bet_policy_spec.rb`, `spec/components/bolao/*_spec.rb`

## Pronto quando
- `create`/`update` só com `match.status == 'scheduled'`; em `live | finished | scored | reverted` → 422 com erro por campo (validação no model, não só no controller)
- BetPolicy: só membro do pool cria/edita; edição só do próprio palpite; `Scope#resolve` = palpites do usuário no pool
- `MatchListComponent`: partidas da rodada com form inline (`PredictionFormComponent` da §5 — ainda não existe em `app/components/ui/`, criar aqui) e countdown até `match_date` (Stimulus; mostra "Palpites encerrados" ao zerar)
- `MyBetsComponent`: por palpite, resultado `exact | winner | miss` e pontos via `Bolao::CalculatePreviewService` com o placar real; depois de `scored`, mostra os pontos persistidos em `Bolao::PredictionScore`
- Componentes com `default | loading | empty | error` + previews Lookbook; sem N+1 (`includes(:match)`)

## Teste antes/depois
- Antes: não há tela de palpites; `Bolao::Prediction` só é criado por factory/admin
- Depois: request spec com 8 exemplos:
  1. palpite em partida `scheduled` → 201/redirect e `Prediction` criado
  2. palpite em partida `live` → 422, nada criado
  3. palpite em partida `finished` → 422, nada criado
  4. edição de palpite com partida ainda `scheduled` → atualizado
  5. edição depois que a partida vira `live` → 422, valores antigos mantidos
  6. não-membro do pool → 403
  7. depois de `finished` + `ProcessMatchPointsJob`, `MyBets` mostra resultado (`exact`/`winner`/`miss`) e pontos (10/5/0)
  8. countdown renderiza `data-countdown-deadline-value` = `match.match_date.iso8601` e "Palpites encerrados" quando `match_date` passou
