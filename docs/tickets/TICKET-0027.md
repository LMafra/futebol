# TICKET-0027 — Seeds de demonstração

- Deps: TICKET-0023, TICKET-0024, TICKET-0025
- Skill: implement (indisponível localmente → [C]lean-build), [W]tdd
- MCP: [neon] dev (opcional; nunca prod)
- Spec: §3 (seeds idempotentes, `belongs_to` sem array), §8 (`ProcessMatchPointsJob`)
- Estado atual: `db/seeds.rb` (TICKET-0022) já tem 20 times, 38 rodadas, admin e guard de produção; `core_matches` não tem coluna `round` (rodada vem do `external_id` `br26-rNN-…`)

## Paths
- `db/seeds.rb`, `db/seeds/demo.rb` (novo)
- `spec/seeds_spec.rb`, `README.md` (seção "Login demo")

## Pronto quando
- 5 usuários `demo1..demo5@demo.local` (senha local fixa documentada; `find_or_create_by!(email_address:)`)
- Pool `DEMO01` (`code: 'DEMO01'`, owner `demo1`) com os 5 usuários como membros
- Rodadas 1–4 e 6 `finished` com placar (`finish_match!`) e pontuadas por `ProcessMatchPointsJob.perform_now` (terminam em `scored`); rodada 5 `live`; rodadas 7–10 `scheduled`
- ≥60 palpites distribuídos entre os 5 usuários e as rodadas, determinísticos (sem `rand` sem seed), um por `(pool, user, match)`
- 1 escalação da rodada 7 com 11 jogadores, formação válida e orçamento ≤ 100
- Idempotente: 2ª carga não cria registros nem re-pontua (job no-op pelo `scoring_token`); guard de produção mantido
- Risco: as datas do seed começam em 2026-04-05, então as rodadas 7–10 ficam com `match_date` no passado — ajustar só as datas das partidas demo `scheduled` para o futuro (countdown do TICKET-0024)

## Teste antes/depois
- Antes: seed só tem admin, times, jogadores e partidas `scheduled`; nenhum pool, palpite ou escalação
- Depois:
  - `bin/rails db:reset` + `db:seed` 2× → contagens idênticas (`User`, `Pool`, `PoolMembership`, `Prediction`, `PredictionScore`, `Lineup`, `LineupPlayer`)
  - `Core::User.where('email_address LIKE ?', '%@demo.local').count == 5`; pool `DEMO01` com 5 membros
  - admin vê pontuação em `/admin` (rodadas 1–4 e 6 `scored` com `PredictionScore` kept)
  - `Rails.env.production?` sem `ALLOW_PRODUCTION_SEED` → `abort`
  - README tem e-mail e senha do login demo
