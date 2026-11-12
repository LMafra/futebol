# TICKET-0078 — Teste usabilidade Red Routes (Admin/Gestor)

- Deps: TICKET-0075, TICKET-0076, TICKET-0077
- Skill: —
- MCP: —
- Spec: métricas Nielsen/Olsen (SEQ, time-on-task, clicks)

## Escopo
- Roteiro e script para 3 Red Routes:
  1. Aprovar 1 gestor pendente (triagem)
  2. Lançar scouts e finalizar 1 partida ao vivo
  3. Criar campeonato mínimo (defaults)
- Instrumentar (manual ou checklist) por tarefa: task success, time-on-task, clicks vs caminho ideal, error rate, SEQ (1–7)
- Documentar baseline vs pós work-queue em `docs/checkpoints/` (resultado do piloto)
- Sem A/B de produto em produção neste ticket — só protocolo + 1 rodada formativa interna

## Paths
- `docs/checkpoints/` (ex.: `UX-RED-ROUTES.md` ou seção no STATUS)
- opcional: seeds/demo que garantam 1 gestor pendente + 1 partida ao vivo

## Pronto quando
- Script de moderação + 3 cenários escritos
- Pelo menos 1 passagem interna registrada (números ou notas SEQ)
- Não bloqueia merge de 0074–0077 se o protocolo estiver pronto; execução pode ser follow-up

## Teste antes/depois
- Antes: validação só por gate RSpec / screenshots
- Depois: Red Routes com SEQ e clicks-to-complete

## Resultado
- Protocolo, cenários e passagem interna em [UX-RED-ROUTES.md](../checkpoints/UX-RED-ROUTES.md) (2026-11-12): 3/3 com sucesso, cliques iguais ao ideal (1, 6, 5), 0 erros.
- Screenshots finais em `docs/checkpoints/ux-audit/after/`, incluindo o modo escuro do sistema.
