# TICKET-0103 — Auditoria e migração das listagens para o componente

- Deps: TICKET-0102
- Skill: [W]tdd
- MCP: playwright
- Origem: rodada de ajustes de 2026-11-12 (grill de listagens)

## Descrição
- **Tabelas largas no celular:** as 14 listagens do Admin e do Gestor eram a tabela padrão do ActiveAdmin. Em 390px, todas eram mais largas que a caixa e escondiam colunas atrás de rolagem lateral.
- **Sem o que o gestor procura:**
  - partidas sem rodada;
  - campeonatos sem inscritos nem próximo passo;
  - times sem escudo;
  - bolões sem código no Admin.
- **ID primeiro:** a primeira coluna e o link principal eram o ID interno.
- **Filas fora da vista:** nos painéis, o próximo passo de cada partida ficava fora da vista no celular.
- Auditoria completa com heurísticas: `docs/checkpoints/UX-LISTAGENS.md`.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Admin (`admin@futebol.dev`) e Gestor (`gestor@demo.local`)

## Severidade
Média: as listas funcionavam, mas no celular metade das colunas ficava escondida e achar uma rodada exigia filtrar.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/matches` em 390px.
2. Procurar a rodada 4 da Copa.

## Esperado
Partidas agrupadas por rodada, com a rodada atual aberta, em cartões que cabem na tela.

## Atual
Lista corrida por data, com Rodada, Data, Placar e Situação fora da vista (`docs/checkpoints/ux-audit/before-0103/gestor-matches-390.png`).

## Correção
- **`AdminCollectionIndex`** (`lib/`): renderizador de índice do ActiveAdmin que entrega a página de registros a um parcial de `app/views/admin/listings/`.
  - Filtros, escopos, paginação e downloads continuam do ActiveAdmin.
  - Desliga a seleção em lote do ActiveAdmin, que envolveria a lista num formulário.
- **`CollectionSortParams`:** `?sort=&dir=` do componente vira o `order` do ActiveAdmin, só para colunas da tabela.
- **`ListingsHelper`:**
  - `listing_counts` faz uma consulta por contagem;
  - `listing_view` e `listing_sort_options` leem a visualização e a ordenação da URL.
- **Listagens:**

  | Listagem | Modo |
  | --- | --- |
  | Campeonatos | cartões com modalidade, inscritos, partidas e próximo passo |
  | Times | grade de escudos ↔ tabela |
  | Jogadores | tabela ordenável |
  | Partidas | por rodada de cada campeonato ↔ agenda |
  | Usuários | tabela ordenável |
  | Bolões | cartões com código e participantes |
  | Importações CSV | tabela |
  | Logs de auditoria e Histórico | linha do tempo por dia |

- **Painéis:** as filas do painel do Admin (ao vivo, pontuação pendente, últimas partidas, pedidos de gestor) e a fila do Gestor viram tabelas do componente. No celular, são cartões com o próximo passo dentro.
- **Painel do Admin:** deixou de rolar para o lado em 390px (`min-w-0` nas colunas do grid).
- **`Ui::CollectionComponent`:**
  - uma coluna que devolve número (contagem) aparece; antes, `capture` a descartava;
  - cartões sem imagem não reservam espaço para ela.
- **Filtros da auditoria em português:** Ação, Quem, Tipo de registro, Quando.
- **Excluir saiu da linha:** continua na página do registro. A exclusão em lote, com confirmação, entra no TICKET-0104.

## Evidência
- `spec/requests/admin/listings_spec.rb`:
  - modo de cada listagem no Admin e no Gestor, sem a tabela do ActiveAdmin;
  - alternância de visualização;
  - ordenação e coluna desconhecida ignorada;
  - contagens, linha do tempo, "Continuar rascunho" e rodada aberta.
- `spec/components/ui/collection_component_spec.rb`: coluna que devolve número.
- Specs do ActiveAdmin, da fila do Gestor, dos pedidos de gestor e do histórico atualizados para o componente.
- Playwright: `docs/checkpoints/ux-audit/before-0103/` e `after-0103/`. Em 390px, nenhuma página rola para o lado (28 telas mais os dois painéis).

## Pronto quando
- [x] Auditoria `docs/checkpoints/UX-LISTAGENS.md` com screenshots antes e depois
- [x] Campeonatos, times, jogadores, partidas, usuários, bolões, CSV e histórico no componente, no Admin e no Gestor
- [x] Filas dos painéis em cartões no celular
- [x] Nenhuma listagem rola para o lado em 390px
