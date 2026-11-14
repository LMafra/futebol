# TICKET-0067 — StatusBadge e Leaderboard com medalhas

- Deps: TICKET-0065, TICKET-0011
- Skill: [W]tdd
- MCP: —
- Spec: design 0001-critique (badge estático)

## Escopo
- `Ui::StatusBadgeComponent` (scheduled/live/finished/reverted)
- `Ui::LeaderboardTableComponent`: thead pitch, zebra paper, medalhas SVG 1–3
- Aplicar badges em index/show de partidas admin e gestor

## Paths
- `app/components/ui/status_badge_component.*`
- `app/components/ui/leaderboard_table_component.*`
- `app/helpers/admin_helper.rb`
- `app/admin/matches.rb`, `app/admin/gestor/matches.rb`
- specs de componente

## Pronto quando
- 4 estados do badge; leaderboard com medalhas; specs verdes
- Sem pulse / glow / emoji

## Teste antes/depois
- Antes: `status_tag` Flowbite; posição só número
- Depois: badge Placar + medalhas SVG
