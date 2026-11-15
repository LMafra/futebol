# TICKET-0104 — Ações em lote nas listagens do Admin e do Gestor

- Deps: TICKET-0103
- Skill: [W]tdd
- MCP: playwright
- Origem: rodada de ajustes de 2026-11-12 (grill de listagens)

## Descrição
- **Uma tela por registro:** a seleção em lote do ActiveAdmin saiu das listagens no TICKET-0103. Inscrever dez times num campeonato, trocar jogadores de time, adiar uma rodada ou aprovar pedidos de gestor exigia abrir cada registro.
- **Exclusão sem relatório:** excluir um time com partidas ou um jogador com lances falhava registro a registro, sem dizer por quê.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Admin (`admin@futebol.dev`) e Gestor (`gestor@demo.local`)

## Severidade
Média: as tarefas eram possíveis uma a uma, mas uma rodada adiada ou uma temporada nova custava dezenas de telas.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/matches` em 390px.
2. Tentar adiar em um dia as partidas da rodada 5.

## Esperado
Selecionar as partidas, informar o deslocamento e o motivo e reagendar todas de uma vez, com o resultado no aviso.

## Atual
Sem seleção: cada partida era editada à parte, e o motivo não ficava registrado.

## Correção
- **Barra de seleção** (`Ui::CollectionComponent`):
  - `c.bulk_fields` põe campos (campeonato, time de destino, deslocamento e motivo) na barra, ao lado da contagem;
  - a barra fica fixa no rodapé, acima do menu inferior no celular (`--sticky-bottom` no layout);
  - as listagens do componente não cortam o conteúdo (`overflow-visible` em `.paginated-collection`). Antes, o corte prendia a barra no fim da lista.
- **`AdminBulkActions`** (`lib/`): registra as ações em lote num recurso do ActiveAdmin.
  - Cada ação é uma `collection_action` que só enxerga registros do escopo do usuário (`scope_collection`).
  - A política autoriza `bulk_*?`: o Gestor nos próprios registros, o Admin em todos; aprovar gestores é só do Admin.
  - Sem seleção: "Selecione pelo menos um item."
  - O resultado volta para a mesma lista como aviso.
- **Serviços** (`app/services/bulk/`), um por ação, com `Bulk::Report`. O relatório conta o que foi feito e o que foi mantido, com o motivo e os nomes:

  | Ação | Onde | Mantém quando |
  | --- | --- | --- |
  | Inscrever no campeonato / Remover do campeonato | Times | já inscrito ou de outro gestor / não inscrito ou com partidas no campeonato |
  | Mover para o time | Jogadores | já está no time ou o número está em uso no destino |
  | Reagendar (dias ou horas, até 365, com motivo) | Partidas | a partida não está agendada |
  | Excluir | Times, Jogadores, Partidas | tem partidas ou jogadores; tem lances ou histórico no Esquadrão; não está agendada, tem palpites ou lances |
  | Aprovar como gestor | Usuários (Admin) | não há pedido pendente |

  Exemplo: "0 excluídos, 2 mantidos porque têm partidas (Botafogo do Capão, Real Paraisópolis)".
- **Auditoria:** cada registro alterado gera um `AuditLog`:
  - `*.destroyed` com `bulk: true`;
  - `player.moved` com origem e destino;
  - `match.rescheduled` com motivo, data antiga e nova.
- **Validação:** reagendar sem deslocamento válido ou sem motivo, inscrever num campeonato de outro gestor e mover sem destino recusam a ação inteira, com a mensagem no aviso.
- **Prosopite:** o laço por registro roda dentro de `Bulk.one_by_one`, que pausa a detecção de N+1 (cada registro é verificado e auditado à parte).

## Evidência
- `spec/requests/admin/bulk_actions_spec.rb`:
  - barra e ações por listagem;
  - times com partidas ou jogadores mantidos na exclusão, e times de outro gestor ignorados;
  - inscrever e remover, e campeonato de outro gestor recusado;
  - mover e excluir jogadores;
  - reagendar com motivo e auditoria, e deslocamento ou motivo inválidos;
  - excluir partidas;
  - aprovar gestores no Admin e 403 no Gestor.
- Playwright em 390px (`docs/checkpoints/ux-audit/after-0104/`):
  - jogadores e partidas com dois itens selecionados e a barra acima do menu inferior;
  - aviso depois da exclusão de times com partidas.

## Pronto quando
- [x] Inscrever e remover times, mover jogadores, reagendar e excluir partidas, aprovar gestores
- [x] Exclusão mantém registros com histórico e diz quais e por quê
- [x] Motivo e `AuditLog` em cada correção
- [x] Barra de seleção visível acima do menu inferior em 390px
