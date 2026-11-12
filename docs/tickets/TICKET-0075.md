# TICKET-0075 — Fila Admin: gestores pendentes com Aprovar inline

- Deps: TICKET-0074, TICKET-0057
- Skill: [W]tdd
- MCP: —
- Spec: blueprint Admin (work queue de triagem)

## Escopo
- No dashboard Admin, logo abaixo dos KPIs: tabela densa de gestores pendentes (Nome · Organização · Data · Ações)
- **Aprovar gestor** = ação primária filled inline (1 clique; Turbo Stream já existe em Usuários)
- **Rejeitar** = secundário/ghost; abre drawer ou campo de justificativa obrigatória (sem modal de “Tem certeza?” genérico)
- Ordenação: pendentes >24h primeiro; depois recentes
- Colunas compactas por padrão; drilldown (accordion/drawer) para perfil/docs sem sair da fila

## Paths
- `app/views/admin/dashboard/_scoring.html.erb` (ou partial `_pending_managers`)
- `app/admin/dashboard.rb`
- recurso de aprovação existente em Usuários / Turbo Stream
- `spec/requests/admin/dashboard_spec.rb`

## Pronto quando
- Triagem de 1 gestor pendente sem navegar para `/users`
- Contador de exceção (pendentes / >24h) visível no 1º viewport
- Gate `test` verde

## Teste antes/depois
- Antes: KPI “gestores pendentes” + link genérico para scope
- Depois: fila de triagem com Aprovar/Rejeitar na linha
