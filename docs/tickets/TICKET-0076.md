# TICKET-0076 — Fila Gestor: 1 CTA por status de partida

- Deps: TICKET-0074, TICKET-0061
- Skill: [W]tdd
- MCP: —
- Spec: blueprint Gestor (ownership / work queue)

## Escopo
- Substituir atalhos globais Scouts/Finalizar/Reverter por **1 ação primária por linha/card**, condicional ao status:
  - Ao vivo → **Lançar Scouts**
  - Scouts em aberto / aguarda finalizar → **Finalizar partida**
  - Agendada → **Editar horário** (ou Iniciar, se aplicável)
  - Pontuada → só badge (sem CTA filled)
  - Exceção → **Reverter** apenas no overflow `…` (atrito + audit; `MatchReversal`)
- Hero do campeonato ativo no topo (nome · rodada · contexto); KPIs locais: partidas hoje · scouts pendentes · participantes bolão (ajustar labels se dados já existirem)
- Overflow `…`: Editar local, Exportar súmula, Reverter, Ver detalhes
- Naming: Verbo + Substantivo; texto (não ícone sozinho) nas ações de domínio

## Paths
- `app/views/gestor/dashboard/_index.html.erb`
- `app/admin/gestor/dashboard.rb`
- helpers de status/ação de partida (se extrair)
- `spec/requests/gestor/dashboard_spec.rb`

## Pronto quando
- Cada item da fila expõe no máximo 1 botão filled
- Reverter não aparece como atalho global
- Gate `test` verde

## Teste antes/depois
- Antes: 5 atalhos iguais + links Finalizar nos cards
- Depois: CTA contextual por estado; overflow para o resto
