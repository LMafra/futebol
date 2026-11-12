# TICKET-0074 — Remover Ações rápidas / Atalhos do 1º viewport

- Deps: TICKET-0070, TICKET-0073, TICKET-0075, TICKET-0076
- Skill: [W]tdd
- MCP: —
- Spec: blueprint work-queue (Hick / CTAs concorrentes)

## Escopo
- Remover o bloco `Ações rápidas` do dashboard Admin (`data-role="admin-quick-actions"`); os 4 KPIs ocupam a largura toda.
- Remover o nav `Atalhos` do dashboard Gestor (`data-role="gestor-shortcuts"`).
- **Criar campeonato** (Admin) e **Novo campeonato** (Gestor) viram `action_item` secundário (branco, borda `graphite`) no cabeçalho da página (`data-role="header-cta"`).
- Gestor: ordem KPIs → Fila de partidas → Seus campeonatos. Sem campeonatos, o empty state "Crie o primeiro" continua no topo.
- 1º viewport = KPIs + início da fila de trabalho (Admin: pedidos de gestor; Gestor: fila de partidas).

## Paths
- `app/admin/dashboard.rb`, `app/admin/gestor/dashboard.rb`
- `app/views/admin/dashboard/_scoring.html.erb`
- `app/views/gestor/dashboard/_index.html.erb`
- `spec/requests/admin/dashboard_spec.rb`, `spec/requests/gestor/dashboard_spec.rb`, `spec/requests/manager_dashboard_spec.rb`

## Pronto quando
- Specs não esperam `admin-quick-actions` / `gestor-shortcuts`
- Criar campeonato acessível via header outline; gate `test` verde

## Teste antes/depois
- Antes: KPIs + 4–5 atalhos no mesmo peso visual
- Depois: KPIs + fila; setup discreto no header (screenshots 1440px do Admin e do Gestor conferidos)
