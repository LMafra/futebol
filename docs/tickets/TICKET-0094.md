# TICKET-0094 — Árvore de navegação, breadcrumbs, páginas de campeonato e time, "Sobre esta tela"

- Deps: TICKET-0089, TICKET-0090, TICKET-0093, TICKET-0102
- Skill: [W]tdd
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 (grill do Gestor), ADR 0006

## Descrição
- **Menus diferentes:** o Admin e o Gestor tinham menus diferentes ("Meus campeonatos", "Auditoria" solto), e as telas de ferramentas da partida (scouts, finalizar, reverter, prévia do bolão) apareciam no menu como se fossem listas.
- **Breadcrumbs seguiam a URL:** uma partida aparecia como "Gestor › Partidas", sem o campeonato; um jogador, sem o time.
- **Páginas soltas:** a página do campeonato não mostrava as partidas nem os bolões; a do time não mostrava os jogadores.
- **Sem explicação:** nenhuma tela dizia para que servia, nem nas Configurações.

## Ambiente
- Celular 390px, Chromium 1208 (Playwright), `/admin` e `/gestor` com os usuários de demonstração

## Severidade
Média: o Gestor se perdia entre campeonato, partida e time, e as telas das fases seguintes precisam desta árvore.

## Passos para reproduzir
1. Entrar como gestor e abrir uma partida em `/gestor/matches/:id`.
2. Olhar o breadcrumb e procurar o caminho de volta para o campeonato.
3. Abrir o campeonato e procurar as partidas e os bolões dele.

## Esperado
O breadcrumb mostra "Gestor › Campeonatos › campeonato › Partidas", e a página do campeonato reúne times inscritos, partidas por rodada e bolões.

## Atual
O breadcrumb mostrava "Gestor › Partidas", e a página do campeonato só tinha os dados do cadastro e as inscrições.

## Correção
- **Mesma árvore nos dois namespaces** (`navigation_tree` em `config/initializers/active_admin.rb`):
  - Campeonatos: Campeonatos, Partidas.
  - Times: Times, Jogadores.
  - Participantes: Bolões e, no Admin, Times do Esquadrão, Rankings do Esquadrão e Usuários; no Gestor, Escalações do Esquadrão.
  - Configurações: Regras do Bolão e, no Admin, Regras do Esquadrão, Testar regras, Importações CSV, Histórico de auditoria e Comentários.
  - Scouts, finalizar, reverter e prévia do bolão saem do menu: são abertas a partir da partida.
- **Breadcrumbs pela árvore** (`AdminBreadcrumbsHelper` + `breadcrumb` do ActiveAdmin):
  - partida sob o campeonato: "Campeonatos › campeonato › Partidas";
  - jogador sob o time: "Times › time › Jogadores";
  - as páginas de ferramentas da partida usam o mesmo caminho e terminam na partida.
- **Página do campeonato** (`AdminRecordPanels.championship`): times inscritos, partidas por rodada (sanfona do `Ui::CollectionComponent`, com a rodada em andamento aberta) e bolões com código e participantes. Vazia, oferece "Agendar partida" e "Criar bolão".
- **Página do time** (`AdminRecordPanels.team`): jogadores do time, com "Cadastrar jogador" já preenchido com o time.
- **"Sobre esta tela"** (`PageIntroHelper` + `dismissible_controller.js`):
  - texto curto por tela em `config/locales/page_intros.pt-BR.yml`, com prioridade para as Configurações;
  - aberto por padrão; fechado, continua fechado naquela tela (`localStorage`).
- "Agendar partida" passa a ser o rótulo único para criar partida a partir do campeonato.

## Evidência
- `spec/requests/admin/navigation_spec.rb` (árvore do Admin e do Gestor) e `spec/requests/gestor/record_pages_spec.rb`
- Playwright 390px: breadcrumbs da partida e dos scouts, "Sobre esta tela" fechado depois de recarregar, páginas do campeonato e do time

## Pronto quando
- [x] Admin e Gestor com a mesma árvore; o Admin vê as telas a mais
- [x] Breadcrumbs da partida e do jogador seguem a árvore
- [x] Página do campeonato com times, partidas por rodada e bolões; página do time com jogadores
- [x] "Sobre esta tela" em todas as telas com texto, lembrando quando foi fechado
