# Tickets — INDEX (22 tickets)

| # | item | título | deps | MCP |
|---|---|---|---|---|
| [0001](TICKET-0001.md) | a | Rails 8 + 4 engines + packwerk | — | neon (opc) |
| [0002](TICKET-0002.md) | b | Core models + seeds idempotentes | 0001 | neon |
| [0003](TICKET-0003-v3.md) | c | AASM + fix guard revert_match! (v3) | 0002 | — |
| [0004](TICKET-0004.md) | d | ProcessMatchPointsJob + Scoring::Engine | 0003 | — |
| [0005](TICKET-0005.md) | e | RevertMatchPointsService (discard + AuditLog) | 0003, 0004 | — |
| [0006](TICKET-0006.md) | f | Preview Bolão candidate_home/away | 0004 | — |
| [0007](TICKET-0007.md) | g | Preview Cartola Data.define | 0002 | — |
| [0008](TICKET-0008.md) | h | BroadcastUpdateService unless_exist | 0004 | — |
| [0009](TICKET-0009.md) | i | ProcessCsvImportJob streaming | 0002 | r2 (opc) |
| [0010](TICKET-0010.md) | j | ActiveAdmin + Pundit (5 policies) | 0005, 0006, 0007, 0009 | — |
| [0011](TICKET-0011.md) | k | Design system + ViewComponents 4 estados | 0001 | — |
| [0012](TICKET-0012-v2.md) | l | CI + deploy Render/Neon + R2 + Resend (v2) | 0001, 0002, 0010, 0014, 0015 | render, neon, r2, resend |
| [0013](TICKET-0013.md) | m | MCP setup + smoke tests | 0001 | neon, render, r2, resend |
| [0014](TICKET-0014.md) | — | Auth (Rails 8 native) | 0001 | — |
| [0015](TICKET-0015.md) | — | Pundit base + 5 policies vazias | 0014 | — |
| [0016](TICKET-0016.md) | — | ScoringRule model + migration | 0002 | neon (opc) |
| [0017](TICKET-0017.md) | — | Scoring::Engine (Strategy Pattern) | 0016 | — |
| [0018](TICKET-0018.md) | — | Users::AnonymizeService (LGPD) | 0014 | — |
| [0019](TICKET-0019.md) | — | Rate limiting em auth endpoints | 0014 | — |
| [0020](TICKET-0020.md) | — | bin/setup + .env.example | 0001 | — |
| [0021](TICKET-0021.md) | — | Solid Queue dashboard + Sentry | 0012 | render (opc) |
| [0022](TICKET-0022.md) | — | db/seeds.rb real | 0002 | neon (opc) |

## Ordem de execução (topológica; numeração não é ordem)
- 0001 → {0002, 0011, 0013, 0014, 0020}
- 0002 → {0003, 0007, 0009, 0016, 0022} · 0014 → {0015, 0018, 0019}
- 0003 → 0004 → {0005, 0006, 0008} · 0016 → 0017
- {0005, 0006, 0007, 0009} → 0010 → 0012 (+ 0014, 0015) → 0021
- 0013 não bloqueia nenhum ticket
