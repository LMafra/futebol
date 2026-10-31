# Fase 7 — Compress (caveman manual)

## Tree
```
futebol/
├── app/{admin,components,jobs(3 stub),services(3 stub),policies(6)}
├── engines/{core,bolao,cartola,simulador}  # 12 migrations TODO
├── docs/{adr/0001,design/0001-*,spec.md,tickets(13+INDEX),mcp,checkpoints,handoffs}
├── spec/  db/seeds.rb  .githooks/pre-commit  .claude/hooks
```

## Tickets
| # | título | deps |
|---|---|---|
| 0001 | Rails+engines+packwerk | — |
| 0002 | core models+seeds | 0001 |
| 0003 | AASM+guard revert | 0002 |
| 0004 | ProcessMatchPointsJob | 0003 |
| 0005 | RevertMatchPointsService | 0003,0004 |
| 0006 | preview Bolão | 0004 |
| 0007 | preview Cartola | 0002 |
| 0008 | Broadcast unless_exist | 0004 |
| 0009 | CSV import streaming | 0002 |
| 0010 | ActiveAdmin+Pundit | 0005-0007,0009 |
| 0011 | design system+VC | 0001 |
| 0012 | CI+deploy | 0001,0002 |
| 0013 | MCP setup | 0001 |

## MCP
- neon: manual (não configurado; db local docker :5440)
- render: manual (deploy hook curl)
- r2: manual (wrangler r2 bucket create)
- resend: manual (curl api.resend.com)

## TICKET-0001
- Gemfile += gems spec §1; validar activeadmin × Rails 8.1
- packwerk: engines → core só; `bin/packwerk check` verde
- Teste: boot_spec 4 engines definidas
