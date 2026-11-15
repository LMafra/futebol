# TICKET-0087 — Legenda das siglas dos scouts

- Deps: TICKET-0084
- Skill: [W]tdd
- MCP: —
- Origem: validação manual da leva 0079–0084 (2026-11-12)

## Descrição
A planilha de scouts do Admin e do Gestor mostra só as siglas G, A, DP, DE, CA, CV, GC e SG, sem explicar o que cada uma é. SG ainda tem dois sentidos no produto: na classificação é "saldo de gols"; no scout é "jogo sem sofrer gols". O top de atletas da home tem o mesmo problema no celular, onde não existe hover para ler o `title`.

## Ambiente
- Desktop 1440px e celular 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Usuários: admin (`admin@futebol.dev`) e gestor (`gestor@demo.local`); visitante na home

## Severidade
Média: quem lança os scouts precisa adivinhar as siglas, o que leva a scout errado e pontuação errada.

## Passos para reproduzir
1. Abrir `/admin/matchscouts?match_id=<partida ao vivo>` (ou `/gestor/matchscouts`).
2. Olhar o cabeçalho da tabela.

## Esperado
Uma legenda acima da tabela explica as siglas. No celular, o cabeçalho mostra o nome por extenso.

## Atual
Só as siglas, sem `abbr` nem legenda. Os botões +/− diziam "Aumentar G de Fulano".

## Correção
- `ScoutLegendHelper`:
  - `SCOUT_ABBREVIATIONS` é a fonte única de sigla e nome, na ordem da pontuação: G, A, SG, DP, DE, CA, CV, GC.
  - `scout_legend` renderiza `<dl aria-label="Legenda dos scouts">`.
  - `abbreviated_header` / `scout_header` mostram `<abbr title>` a partir de 640px e o nome por extenso abaixo disso.
- Planilha de scouts (Admin e Gestor, mesmo partial): legenda acima das abas dos times, cabeçalhos com `scout_header`, e os botões +/− passam a dizer "Aumentar Gol de Fulano".
- `Ui::LeaderboardTableComponent` usa `abbreviated_header` nas colunas extras (top de atletas: J, G, A).
- `tailwind-active_admin.config.js` passa a ler `scout_legend_helper.rb`.
- Gate: `spec/seeds_spec.rb` falhava às vezes (um Top 3 do Esquadrão com −1 ponto), porque os scouts de demonstração usavam `match.id`, que muda com a sequência do banco. `db/seeds/scouts.rb` passa a usar uma chave estável do `external_id` da partida.

## Evidência
- Navegador (Playwright): em 1440px os cabeçalhos ficam `G A DP DE CA CV GC SG` com a legenda acima; em 390px ficam `GOL, ASSISTÊNCIA, …, JOGO SEM SOFRER GOLS`.
- `spec/helpers/scout_legend_helper_spec.rb`; `match_scouts_spec`, `accessibility_spec` e `leaderboard_table_component_spec` atualizados.

## Pronto quando
- Toda tabela com sigla de scout tem legenda ou `abbr` com nome por extenso no celular
- Gate `test` verde
