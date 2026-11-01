# Spec — Futebol (Bolão · Cartola · Simulador)

Inputs: `docs/handoffs/PHASE-1.md` (warning: input inferido) · `docs/handoffs/PHASE-2.5.md` (ok, 1 violação tratada em §4)
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
add_check_constraint :matches, "status IN ('scheduled','live','finished','scored')", name: 'matches_status_valid'
add_check_constraint :matches, "(status = 'scored') = (scores_calculated_at IS NOT NULL)", name: 'matches_scored_has_timestamp'
add_check_constraint :matches, 'home_team_id <> away_team_id', name: 'matches_distinct_teams'
add_check_constraint :matches, 'home_score >= 0 AND away_score >= 0', name: 'matches_scores_non_negative'
```
- Demais tabelas: `teams(external_id uniq)`, `championships`, `users`, `audit_logs(user_id, action, auditable polymorphic, ip_address inet not null, metadata jsonb)`, `csv_imports(status, error_message, rows_processed)` + check `status IN ('pending','processing','completed','failed')`
- Bolão: `pools`, `predictions(home_guess, away_guess, discarded_at)` check `>= 0`, `prediction_scores(points, scoring_token, discarded_at)` unique `(prediction_id, scoring_token)`
- Cartola: `squads`, `lineups`, `player_scores(points numeric(6,2), discarded_at)`
- `discarded_at` + índice em toda tabela de score/prediction

## 3. Models e state machine
- `Core::Match` — `include AASM`, `aasm column: :status`; eventos conforme ADR 0001 §2
```ruby
event :revert_match do
  transitions from: :scored, to: :finished, guard: :scores_calculated?, after: :revert_points_then_clear
end

def revert_points_then_clear
  RevertMatchPointsService.call(match: self, actor: Current.user, ip_address: Current.ip_address)
  assign_attributes(scores_calculated_at: nil, scoring_token: nil, reversal_token: SecureRandom.uuid)
end
```
- Ordem AASM: guard (lê `scores_calculated_at`) → transition `after` (revert + assign, sem save) → AASM salva status + colunas zeradas no mesmo `save` transacional
- Não usar `before` do evento: roda antes dos guards. Não usar `update!` separado: viola `matches_scored_has_timestamp`
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
- Regra Bolão (Scoring::Engine): placar exato 10 · vencedor+saldo 7 · vencedor 5 · empate não exato 3 · erro 0
- `CalculatePreviewService` reutiliza `Scoring::Engine` com `candidate_home/candidate_away` no lugar do placar real

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
