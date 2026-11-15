# TICKET-0116 — Tabelas escaneáveis com badges triplos

- Deps: TICKET-0115
- Skill: [W]tdd
- MCP: —

## Escopo
- `Ui::StatusBadgeComponent` com ícone + texto + cor (incl. `pending_scouts`)
- `Ui::AdminTableComponent` thead display/xs, zebra, coluna de ações
- Listagem de partidas: Data/Hora, Confronto, Situação, Placar, Rodada, Ação + kebab
- Paginação "Exibindo X–Y de Z"

## Paths
- `app/components/ui/status_badge_component*`
- `app/components/ui/admin_table_component*`
- `app/views/admin/listings/_matches.html.erb`
- `config/locales/active_admin_pagination.pt-BR.yml`

## Pronto quando
- [ ] StatusBadge 5+ estados com ícones
- [ ] AdminTable pitch/zebra/ações
- [ ] Tabela 6 colunas + kebab
- [ ] Specs verdes
