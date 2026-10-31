# Tickets — INDEX (ordem topológica)

| # | item | título | deps | MCP |
|---|---|---|---|---|
| [0001](TICKET-0001.md) | a | Rails 8 + 4 engines + packwerk | — | neon (opc) |
| [0002](TICKET-0002.md) | b | Core models + seeds idempotentes | 0001 | neon |
| [0003](TICKET-0003.md) | c | AASM + fix guard revert_match! | 0002 | — |
| [0004](TICKET-0004.md) | d | ProcessMatchPointsJob + Scoring::Engine | 0003 | — |
| [0005](TICKET-0005.md) | e | RevertMatchPointsService (discard + AuditLog) | 0003, 0004 | — |
| [0006](TICKET-0006.md) | f | Preview Bolão candidate_home/away | 0004 | — |
| [0007](TICKET-0007.md) | g | Preview Cartola Data.define | 0002 | — |
| [0008](TICKET-0008.md) | h | BroadcastUpdateService unless_exist | 0004 | — |
| [0009](TICKET-0009.md) | i | ProcessCsvImportJob streaming | 0002 | r2 (opc) |
| [0010](TICKET-0010.md) | j | ActiveAdmin + Pundit (5 policies) | 0005, 0006, 0007, 0009 | — |
| [0011](TICKET-0011.md) | k | Design system + ViewComponents 4 estados | 0001 | — |
| [0012](TICKET-0012.md) | l | CI + deploy Render/Neon + R2 + Resend | 0001, 0002 | render, neon, r2, resend |
| [0013](TICKET-0013.md) | m | MCP setup + smoke tests | 0001 | neon, render, r2, resend |

## Paralelização após 0001
- Trilha domínio: 0002 → 0003 → 0004 → {0005, 0006, 0008} → 0010
- Trilha paralela: 0007, 0009 (após 0002) · 0011, 0013 (após 0001) · 0012 (após 0002)
