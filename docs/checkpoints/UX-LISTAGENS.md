# Auditoria das listagens — Admin e Gestor (TICKET-0103)

Avaliação heurística das listagens do Admin e do Gestor antes e depois da migração para `Ui::CollectionComponent` (guia: `docs/ux/listagens.md`). Usa as 10 heurísticas de Nielsen e critérios de IHC (lei de Fitts para alvos de toque, reconhecimento em vez de memória, agrupamento por proximidade).

Passagem interna feita pelo agente com Playwright (Chromium 1208) nos dados de demonstração, em 1440px e 390px. Não substitui sessão com pessoas.

- Antes: `docs/checkpoints/ux-audit/before-0103/{admin,gestor}-{tela}-{1440,390}.png`
- Depois: `docs/checkpoints/ux-audit/after-0103/` (mesmos nomes; mais `admin-teams-table-390`, `admin-matches-agenda-390` e os dois painéis em 390px)
- Script: `tmp/pw/listings0103.js <pasta>`. Ele imprime, por tela, se a página rola para o lado, quantas tabelas há e se alguma tabela é mais larga que a caixa.

## Antes

Todas as 14 telas (9 do Admin, 5 do Gestor) eram a tabela padrão do ActiveAdmin: ID na primeira coluna, ícones de ação no fim e as mesmas colunas no celular. Em 390px, **todas as tabelas eram mais largas que a caixa** e rolavam para o lado dentro do painel. A página não rolava, mas metade das colunas ficava fora da vista.

| # | Problema | Heurística | Severidade (0–4) | Telas |
| --- | --- | --- | --- | --- |
| 1 | Tabela larga no celular: colunas escondidas atrás de rolagem lateral, sem indicação de que há mais (`before-0103/gestor-matches-390.png`) | Visibilidade do estado do sistema; flexibilidade e eficiência | 3 | todas |
| 2 | ID como primeira coluna e link principal: um número interno no lugar mais visível; o nome do campeonato, time ou jogador vinha depois | Correspondência com o mundo real; reconhecimento em vez de memória | 2 | todas |
| 3 | Partidas numa lista corrida por data, sem rodada: para achar "a rodada 4 da Copa" era preciso filtrar | Correspondência com o mundo real; flexibilidade | 3 | partidas (Admin e Gestor) |
| 4 | Campeonatos sem modalidade, inscritos ou próximo passo: um rascunho parecia igual a um publicado, exceto por uma etiqueta | Visibilidade do estado; reconhecimento em vez de memória | 2 | campeonatos |
| 5 | Times sem escudo: o escudo é como o gestor reconhece o time, mas a lista só tinha texto | Reconhecimento em vez de memória | 2 | times |
| 6 | Bolões sem o código e sem participantes no Admin; o gestor precisava abrir o bolão para compartilhar o código | Flexibilidade e eficiência | 2 | bolões |
| 7 | Auditoria em tabela de 6 colunas, com o motivo cortado; difícil ver o que aconteceu num dia | Estética e design minimalista; ajuda a diagnosticar | 2 | logs de auditoria, histórico |
| 8 | Filtros da auditoria em inglês ("Action", "Auditable type", "Created at") | Correspondência com o mundo real; consistência | 2 | logs de auditoria |
| 9 | Fila de partidas do Gestor e filas do painel do Admin como tabelas: no celular, o botão do próximo passo ficava fora da vista | Visibilidade do estado; lei de Fitts | 3 | painéis |
| 10 | Cada tela com um jeito de mostrar ações (ícones do ActiveAdmin, links soltos, menu "⋯") | Consistência e padrões | 1 | todas |

## Depois

As telas passaram para o componente por um renderizador de índice do ActiveAdmin (`AdminCollectionIndex`). Filtros, escopos, paginação e downloads continuam do ActiveAdmin; a lista é do componente. Ordenação pelos cabeçalhos (`?sort=&dir=`) vira o `order` do ActiveAdmin, só para colunas reais.

| Tela | Modo | O que mudou |
| --- | --- | --- |
| Campeonatos | `cards` | Logo, temporada, modalidade, times inscritos, partidas, situação e próximo passo ("Continuar rascunho" ou "Abrir") |
| Times | `grid` ↔ `table` | Grade de escudos com o número de jogadores; tabela com sigla, capitão e gestor (Admin) |
| Jogadores | `table` | Nome primeiro; ordenar por nome, posição, número e valor base; cartões no celular |
| Partidas | `grouped` ↔ `agenda` | Por rodada de cada campeonato, com a primeira rodada que tem jogo por fazer aberta; agenda por dia com semana anterior/próxima; próximo passo em cada partida |
| Usuários | `table` | Nome, e-mail, papel, pedido de gestor e cadastro; ordenar por nome, e-mail e cadastro |
| Bolões | `cards` | Campeonato, código, participantes e dono (Admin) |
| Importações CSV | `table` | "Importação #N" como título, situação, linhas, erro e data |
| Logs de auditoria e Histórico | `timeline` | Um dia por grupo: hora, ação, quem, registro, motivo e IP; filtros em português |
| Painel do Admin (ao vivo, pendentes, últimas partidas, pedidos de gestor) e fila do Gestor | `table` | Cartões no celular, com o próximo passo dentro do cartão |

Medição em 390px depois da migração: nenhuma página rola para o lado e nenhuma tabela passa da caixa (28 de 28 telas, mais os dois painéis). O painel do Admin rolava para o lado pela coluna principal do grid (`min-w-0` ausente) e pela tabela de pedidos de gestor; os dois foram corrigidos.

## Decisões

- **Seleção em lote do ActiveAdmin desligada nas telas migradas.** O formulário de lote do ActiveAdmin envolveria a lista e o componente tem a própria seleção; as ações em lote voltam pelo componente no TICKET-0104.
- **Excluir saiu da linha.** Continua na página do registro, que confirma e explica o que acontece; ações destrutivas na lista só em lote, com confirmação (0104).
- **ID fora da lista.** Continua na página do registro e no filtro "ID externo".

## Pendências

- O ActiveAdmin ainda mostra a própria tela vazia quando não há registros (ex.: Importações CSV nos dados de demonstração). A tela vazia do componente, com a ação de criar, aparece só nas páginas de campeonato e time.
- Ordenar por contagens (jogadores, inscritos, participantes) exige colunas de contagem no banco; por enquanto só colunas reais são ordenáveis.
