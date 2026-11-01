# Spec — Futebol (Bolão · Cartola · Simulador)

Inputs: `docs/handoffs/PHASE-1.md` (warning: input inferido) · `docs/handoffs/PHASE-2.5.md` (ok, 1 violação tratada em §4)
Versão: v3 (TIER-2 / TICKET-0003) — resolve os 4 conflitos de `docs/checkpoints/PHASE-3-v2.yaml`; muda só §2 (constraints de `matches`), §3 (justificativa AASM) e "Specs de regressão obrigatórias".
Stack: Ruby 3.3.6 · Rails 8.1 · PostgreSQL (Neon) · Solid Queue · Hotwire · Tailwind

## 1. Gems (versões fixadas em 2026-10-31 via rubygems API)
| gem | versão | uso |
|---|---|---|
| aasm | ~> 6.0 | state machine Match |
| discard | ~> 2.0 | soft delete scores/predictions |
| activerecord-import | ~> 3.0 | upsert em lote (CSV) |
| pundit | ~> 2.5 | policies por action |
| activeadmin | ~> 3.5 | admin + custom pages |
| view_component | ~> 4.20 | componentes UI |
| lookbook | ~> 2.3 (dev) | previews dos 4 estados |
| stoplight | ~> 6.0 | circuit breaker p/ APIs externas |
| faraday | ~> 2.15 | HTTP client |
| sentry-ruby / sentry-rails | ~> 7.2 | erros |
| lograge | ~> 0.15 | logs 1 linha JSON |
| turbo-rails | ~> 2.0 | Turbo Streams/Frames |
| stimulus-rails · tailwindcss-rails | ~> 1.3 · ~> 4.7 | front |
| packwerk | ~> 3.3 (dev) | fronteiras de engines |
| rspec-rails · factory_bot_rails | ~> 8.0 · ~> 6.5 (dev/test) | testes |
| pg · solid_queue | ~> 1.7 · ~> 1.7 | DB · jobs |

Riscos: activeadmin 3.5 × Rails 8.1 (validar no TICKET-0001; fallback branch `master`/4.0-beta). tailwindcss-rails 4 = Tailwind v4 (config CSS-first) → `tailwind.config.js` carregado via `@config`.

## 2. Migrations (engine core; `add_check_constraint`, nunca `add_constraint`)
```ruby
create_table :matches do |t|
  t.references :home_team, null: false, foreign_key: { to_table: :teams }
  t.references :away_team, null: false, foreign_key: { to_table: :teams }
  t.references :championship, null: false, foreign_key: true
  t.datetime :match_date, null: false
  t.integer :home_score, :away_score
  t.string :status, null: false, default: 'scheduled'
  t.datetime :scores_calculated_at
  t.uuid :scoring_token, :reversal_token
  t.string :external_id, null: false
  t.timestamps
end
add_index :matches, :external_id, unique: true
add_index :matches, :scoring_token, unique: true, where: 'scoring_token IS NOT NULL'
add_check_constraint :matches, "status IN ('scheduled','live','finished','scored','reverted')", name: 'matches_status_valid'
add_check_constraint :matches, "status <> 'scored' OR scores_calculated_at IS NOT NULL", name: 'matches_scored_has_timestamp'
add_check_constraint :matches, "scores_calculated_at IS NULL OR status IN ('finished','scored')", name: 'matches_timestamp_after_finish'
add_check_constraint :matches, 'home_team_id <> away_team_id', name: 'matches_distinct_teams'
add_check_constraint :matches, 'home_score >= 0 AND away_score >= 0', name: 'matches_scores_non_negative'
```
- Demais tabelas: `teams(external_id uniq)`, `championships`, `users`, `audit_logs(user_id, action, auditable polymorphic, ip_address inet not null, metadata jsonb)`, `csv_imports(status, error_message, rows_processed)` + check `status IN ('pending','processing','completed','failed')`
- Bolão: `pools`, `predictions(home_guess, away_guess, discarded_at)` check `>= 0`, `prediction_scores(points, scoring_token, discarded_at)` unique `(prediction_id, scoring_token)`
- Cartola: `squads`, `lineups`, `player_scores(points numeric(6,2), discarded_at)`
- `discarded_at` + índice em toda tabela de score/prediction

## 3. Models e state machine
- `Core::Match` — `include AASM`, `aasm column: :status, whiny_persistence: true`; eventos conforme ADR 0001 §2, com um estado `reverted` (destino de `revert_match!`, de `scored` ou `finished`; `mark_scored!` aceita `finished | reverted`)
- O guard `:scores_calculated?` lê o valor em memória; por isso `revert_match!` roda ANTES de zerar `scores_calculated_at`. Ordem real do AASM 6.0.0 (`lib/aasm/aasm.rb#aasm_fire_event`): event `before` → guards → transition `after` → escrita do estado (1 `save`). Implementação: `transitions from: %i[scored finished], to: :reverted, guard: :scores_calculated?, after: :clear_scores`; `clear_scores` só atribui (`scores_calculated_at = nil`, `scoring_token = nil`, `reversal_token = SecureRandom.uuid`) e o AASM persiste tudo em um único `save` junto com `status = 'reverted'`. Não há segundo `save!`, e nada é zerado fora do model (`update_column` externo está proibido). Event `before` não pode ser usado para zerar, porque roda antes dos guards.
- Seeds: `belongs_to` sempre recebe 1 registro (nunca array); `find_or_create_by!(external_id:)` → idempotente

## 4. Design system → `config/tailwind.config.js`
```js
module.exports = {
  theme: {
    colors: {
      paper: '#F4F1EA', pitch: '#0B6B3A', cartola: '#E85D04', ink: '#161616',
      graphite: '#4A4A45', rule: '#D9D3C4', night: '#0E1A13', white: '#FFFFFF', transparent: 'transparent',
      win: 'rgb(11 107 58 / 0.15)', draw: 'rgb(138 133 119 / 0.15)', loss: 'rgb(164 22 26 / 0.15)'
    },
    fontFamily: {
      display: ['Fraunces', 'Bitter', 'Georgia', 'serif'],
      sans: ['"Source Sans 3"', '"IBM Plex Sans"', 'system-ui', 'sans-serif']
    },
    spacing: { 0: '0', 1: '4px', 2: '8px', 3: '12px', 4: '16px', 6: '24px', 8: '32px', 12: '48px', 16: '64px' },
    borderRadius: { none: '0', sm: '4px', md: '8px', lg: '16px' },
    boxShadow: { none: 'none', sm: '0 1px 2px rgb(22 22 22 / .06)', md: '0 2px 6px rgb(22 22 22 / .08)' },
    transitionDuration: { fast: '120ms', base: '150ms', slow: '180ms' },
    transitionTimingFunction: { editorial: 'cubic-bezier(.2,.8,.2,1)' },
    extend: { gridTemplateColumns: { admin: 'repeat(12, minmax(0, 1fr))' } }
  }
}
```
- `app/assets/tailwind/application.css`: `@import "tailwindcss"; @config "../../../config/tailwind.config.js";`
- Regras da critique: win/draw/loss só tint + glifo V/E/D; `font-display` só ≥ `text-xl`; números `tabular-nums`; sem gradient/blur/glow (lint: grep CI bloqueia `bg-gradient|backdrop-blur|shadow-.*-500`)

## 5. ViewComponents (4 estados obrigatórios: `default | loading | empty | error`)
| componente | default | loading | empty | error |
|---|---|---|---|---|
| `ScoreboardComponent(match:)` | placar TV 2/8/2 | skeleton linhas 64px | "Sem jogos nesta rodada" | faixa `loss` + retry Turbo |
| `StandingsTableComponent(rows:)` | tabela classificação | skeleton 10 linhas | "Rodada ainda não pontuada" | mensagem + link log |
| `PredictionFormComponent(match:, prediction:)` | form palpite | botão disabled + spinner | "Palpites encerrados" | erros por campo |
| `PreviewPanelComponent(preview:)` | pontos simulados | skeleton | "Informe um placar candidato" | erro do service |
| `CsvImportStatusComponent(csv_import:)` | progresso | processing | "Nenhuma importação" | `error_message` |
- Interface comum: `initialize(..., state: :default)`; `STATES = %i[default loading empty error].freeze`; `validates_inclusion` no init
- Lookbook: 1 preview por estado em `spec/components/previews/`

## 6. ActiveAdmin custom pages (todas com `authorize` Pundit)
| page | actions | policy |
|---|---|---|
| `admin/matches` | index, show, `member_action :revert` (PUT), `:preview` (GET) | MatchPolicy (`revert?`, `preview?`) |
| `admin/csv_imports` | index, new, create (upload), show | CsvImportPolicy (`import?`) |
| `admin/pools`, `admin/squads` | CRUD | PoolPolicy, SquadPolicy |
| `admin/audit_logs` | index, show (read-only) | AuditLogPolicy |
| `Page "Scoring Dashboard"` | painel 8/4: partidas finished pendentes / log | MatchPolicy#index? |

## 7. Services
```ruby
Bolao::CalculatePreviewService.call(match:, candidate_home:, candidate_away:) # => Data Preview(rows:, total:)
Scoring::Engine.points_for(prediction:, home:, away:)                          # puro, sem I/O
Cartola::CalculatePreviewService.call(lineup:, stats:)                         # dry-run Data.define, sem persistir
RevertMatchPointsService.call(match:, actor:, ip_address:)                     # transação: discard scores + AuditLog
BroadcastUpdateService.call(match:)                                            # Rails.cache.write(key, 1, unless_exist: true, expires_in: 5.seconds)
```
- Regra Bolão (2 faixas, [ADR 0004](adr/0004-bolao-scoring.md), TICKET-0029): placar exato = `exact_score_points` (padrão 10) · vencedor ou empate certo com placar errado = `winner_points` (padrão 5) · erro 0. Regra 10/7/5/3 anterior substituída
- `CalculatePreviewService` e `ProcessMatchPointsJob` chamam `Bolao::ScoringRule#points_for` com `candidate_home/candidate_away` (preview) ou o placar real (job); ver §10

## 8. Jobs
```ruby
class ProcessMatchPointsJob < ApplicationJob
  def perform(match_id, scoring_token)
    match = Core::Match.find(match_id)
    return if match.scoring_token == scoring_token # idempotente
    # calcula + insert prediction_scores(scoring_token) + match.mark_scored!
  rescue StandardError => e
    Rails.logger.error(...); Sentry.capture_exception(e); raise
  end
end

class ProcessCsvImportJob < ApplicationJob
  def perform(csv_import_id)
    import = Core::CsvImport.find(csv_import_id)
    import.update!(status: 'processing')
    import.csv_file.open do |file|                        # streaming ActiveStorage, NÃO CSV.read
      CSV.foreach(file.path, headers: true).each_slice(500) do |batch|
        Core::Match.import(rows_for(batch), on_duplicate_key_update: { conflict_target: [:external_id], columns: UPSERT_COLUMNS })
      end
    end
    import.update!(status: 'completed')
  rescue StandardError => e
    import&.update!(status: 'failed', error_message: e.message)
  end
end
```
- `RevertMatchPointsJob(match_id, reversal_token)`: no-op se `match.reversal_token == reversal_token`; chama `match.revert_match!`

## 9. Não-funcionais
- Lograge JSON; Sentry DSN via ENV; Stoplight em clientes Faraday
- Deploy: Render (web + worker Solid Queue), Neon Postgres, R2 (ActiveStorage S3), Resend (ActionMailer), keep-alive em `/up`

## 10. Produto (lacunas resolvidas nos TICKET-0028..0031)

### Bolão
- `bolao_scoring_rules(championship_id, pool_id, exact_score_points default 10, winner_points default 5)`: uma linha por escopo. Os dois nulos = global; `championship_id` = regra do campeonato; `pool_id` = override do bolão. Check `exact_score_points >= winner_points >= 0` e `pool_id IS NULL OR championship_id IS NULL`; unique `(championship_id, pool_id)` com `nulls_not_distinct`
- Resolução: override do bolão → regra do campeonato → global → padrão 10/5 (`ScoringRule.by_pool(pools)`, 1 query)
- `ScoringRule#points_for(prediction_home, prediction_away, actual_home, actual_away)` → `{ points:, result: :exact | :winner | :miss }`; empate certo com placar errado é `:winner`
- Admin: "Regras do Bolão" (escopo + "Pontos por placar exato" + "Pontos por vencedor") e "Pontuação própria" no form do bolão

### Cartola
- Por campeonato (`core_championships`): `cartola_goalkeeper_limit` 1, `cartola_defender_limit` 2, `cartola_midfielder_limit` 3, `cartola_forward_limit` 3 (máximos por posição; defensor + meio + atacante > 0), `cartola_initial_budget` 100, `cartola_base_player_value` 5
- Posições: `core_players.position` segue `GOL/LAT/ZAG/MEI/ATA`; vagas do Cartola = `goalkeeper` (GOL), `defender` (LAT, ZAG), `midfielder` (MEI), `forward` (ATA), gravadas em `cartola_lineup_players.position`
- Escalação (`cartola_lineups`, unique `squad_id, championship_id, round`): ≥ 1 jogador e cada posição dentro do limite; a formação é preset de UI (vagas = `min(preset, limite)`)
- Preço: `Cartola::PlayerValue` atual → `core_players.base_value` → `cartola_base_player_value`
- `Cartola::Wallet` (unique `user_id, championship_id`, `balance >= 0`, aberta com o orçamento inicial): `WalletService.save` debita os jogadores novos e credita os retirados a preço atual; `WalletService.destroy` devolve a escalação. Cada rodada é uma compra própria
- `Cartola::ValueUpdateJob(match_id, scoring_token)`, enfileirado pelo `ProcessMatchPointsJob`: `novo = atual × (1 + (pontos − média da partida) / 100)`, limitado a ±20%; histórico em `cartola_player_value_histories` (unique `player_id, scoring_token`); o Reversal desfaz pelo mesmo token
- `core_matches.round` (1..38; CSV aceita coluna `round` opcional). Rankings (`/cartola/rankings`, abas Pontos e Cartoletas): pontos = `PlayerScore` mantidos dos jogadores de cada escalação nas partidas da mesma rodada; moedas = saldo da carteira

## Specs de regressão obrigatórias
```ruby
# spec/models/core/match_spec.rb
RSpec.describe Core::Match, type: :model do
  describe "#revert_match!" do
    it "reverte com scores_calculated_at presente e zera depois" do
      calculated_at = 1.hour.ago.change(usec: 0)
      match = create(:match, status: :finished, scores_calculated_at: calculated_at)
      seen_by_guard = []
      allow(match).to receive(:scores_calculated?).and_wrap_original do |original, *args|
        seen_by_guard << match.scores_calculated_at
        original.call(*args)
      end

      expect { match.revert_match! }.to change { match.reload.status }.from("finished").to("reverted")
      expect(seen_by_guard).to be_present
      expect(seen_by_guard).to all(eq(calculated_at))
      expect(match.reload.scores_calculated_at).to be_nil
    end

    it "falha o guard se scores_calculated_at for nil" do
      match = create(:match, status: :finished, scores_calculated_at: nil)
      expect { match.revert_match! }.to raise_error(AASM::InvalidTransition)
    end
  end
end
```
