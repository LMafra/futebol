# TICKET-0088 — Busca só por nome, com autocomplete, e selects simples nos filtros

- Deps: TICKET-0084
- Skill: [W]tdd
- MCP: —
- Origem: validação manual da leva 0079–0084 (2026-11-12)

## Descrição
Os filtros das listagens do Admin e do Gestor herdavam o padrão do ActiveAdmin:
- todo campo de texto vinha com um seletor "Contém / Igual a / Começa com / Termina com";
- havia filtros de pouco uso (sigla, ID externo como texto livre);
- rodada e temporada eram campos numéricos com operadores (igual, maior, menor).

Para encontrar um time, o gestor precisava escolher um operador e acertar a grafia exata do nome.

## Ambiente
- Desktop 1440px, Chromium 1208 (Playwright), Rails 8.1 dev local, ActiveAdmin 4.0.0.beta23
- Usuários: admin (`admin@futebol.dev`) e gestor (`gestor@demo.local`)

## Severidade
Média: aumenta o custo de toda busca nas listagens e confunde quem não conhece os operadores.

## Passos para reproduzir
1. Abrir `/gestor/teams` (ou `/gestor/players`, `/gestor/championships`, `/gestor/pools`).
2. Olhar o filtro "Nome" e o filtro "Rodada" em `/gestor/matches`.

## Esperado
Um campo "Nome" simples, com sugestões enquanto digita, e selects simples para status, campeonato, rodada e temporada.

## Atual
Seletor de operador ao lado do nome, sem sugestões; rodada com operadores numéricos.

## Correção
- `AdminNameSearch.register(self)` (em `lib/admin_name_search.rb`):
  - registra o filtro `name_cont` como campo simples (`as: :string`, rótulo "Nome", `autocomplete="off"`, `data-controller="autocomplete"`);
  - registra a ação `GET <listagem>/autocomplete?q=`, que devolve até 8 nomes em JSON.
  - As sugestões passam pelo escopo do Pundit (`apply_authorization_scope`), então o gestor só vê nomes que pode listar. Exigem 2 letras e tratam `%`/`_` como texto.
- `ApplicationPolicy#autocomplete?` segue `index?`.
- `autocomplete_controller.js` (registrado no importmap do Admin) cria um `<datalist>` ligado ao campo e o preenche com atraso de 200ms. O `<datalist>` é nativo, então teclado e leitor de tela já funcionam.
- Aplicado em:
  - **Admin:** campeonatos, times, jogadores, bolões, regras e times do Esquadrão, e usuários.
  - **Gestor:** campeonatos, times, jogadores e bolões.
- Selects simples:
  - **Rodada (1–38):** partidas do Admin e do Gestor, e escalações do Gestor.
  - **Temporada:** campeonatos.
  - **Ação e tipo:** auditoria.
- Saem a sigla dos times e o ID externo como texto com operadores. O ID externo vira busca exata (`external_id_eq`) no Admin.

## Evidência
- Navegador (Playwright): em `/gestor/teams`, digitar "Rea" → `<datalist id="q_name_cont-suggestions">` com "Real Paraisópolis"; nenhum `select` de operador no formulário de filtros.
- `spec/requests/admin/name_search_spec.rb`: campo sem operador, escopo do gestor, ordem alfabética do admin, mínimo de 2 letras, 403 para usuário comum, selects de rodada/temporada.

## Pronto quando
- Nenhum filtro de texto com seletor de operador
- Gate `test` verde
