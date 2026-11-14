# TICKET-0076 — Fila Gestor: 1 CTA por status de partida

- Deps: TICKET-0061, TICKET-0081
- Skill: [W]tdd
- MCP: —
- Spec: blueprint Gestor (ownership / work queue)

## Escopo
- A seção "Próximas partidas" vira **Fila de partidas** (`Gestor::MatchQueue`). A fila traz:
  - as partidas abertas (agendada, ao vivo, encerrada, revertida), por horário de início, até 10;
  - as 3 últimas pontuadas.
- **1 ação primária por linha**, conforme o estado. A presença de scouts vem de um único `pluck` em `Cartola::PlayerScore.kept`.
  - agendada no futuro → **Editar partida**
  - agendada vencida, ou ao vivo sem scouts → **Lançar scouts**
  - ao vivo com scouts → **Finalizar partida**
  - encerrada → sem CTA, badge **Pontuando**
  - pontuada → sem CTA, badge **Pontuada** (novo estado `scored` no `Ui::StatusBadgeComponent`; `admin_match_status_badge` deixa de mapear `scored` para `finished`)
  - revertida → sem CTA, "Aguardando nova pontuação"
- Overflow `⋯` (`<details>`) por linha: Ver partida, Editar partida (agendada) e **Reverter pontuação** (só quando `may_revert_match?` e autorizado).
- KPIs do Gestor: Partidas hoje · Aguardando scouts · Aguardando finalização.
- Cards de campeonato sem "Finalizar"; atalhos globais Scouts/Finalizar/Reverter removidos (o resto dos atalhos sai no TICKET-0074).
- Colunas com `text-right` passam a alinhar também no `th` da `data-table`.

## Fora do escopo (registrado)
- Hero do campeonato ativo e o overflow "Exportar súmula" não existem como dado/rota hoje. Ficam fora; o overflow cobre Ver/Editar/Reverter.

## Paths
- `app/services/gestor/match_queue.rb` (novo)
- `app/admin/gestor/dashboard.rb`
- `app/views/gestor/dashboard/_index.html.erb`, `app/views/gestor/dashboard/_match_queue.html.erb`
- `app/components/ui/status_badge_component.rb` (`scored`, `label:`)
- `spec/services/gestor/match_queue_spec.rb`, `spec/requests/gestor/dashboard_spec.rb`

## Pronto quando
- Cada item da fila expõe no máximo 1 botão filled
- Reverter não aparece como atalho global
- Gate `test` verde

## Teste antes/depois
- Antes: 5 atalhos iguais + links Finalizar nos cards e em cada linha
- Depois: CTA contextual por estado; overflow para o resto (dev: 6 agendadas com "Editar partida", 3 pontuadas com badge "Pontuada")
