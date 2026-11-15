# TICKET-0112 — Histórico da partida na página da partida

- Deps: TICKET-0111
- Skill: [W]tdd
- MCP: playwright
- Origem: pedido do gestor (2026-11-14): "com capacidade de ver o que foi feito anteriormente"

## Descrição
Com a partida editável depois de pontuada (TICKET-0111), o gestor precisa ver o que já foi feito nela: quais lances entraram e saíram, quando foi finalizada, como o placar mudou e quem reverteu. A auditoria já registrava tudo isso, mas só no "Histórico de auditoria" do Admin, com o nome técnico da ação. O Gestor não tinha acesso a ela.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`), partida 387 (editada no TICKET-0111)

## Severidade
Média: sem o histórico, uma correção depois da pontuação não deixa rastro visível para quem administra o campeonato.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/matches/387`.
2. Procurar o que foi alterado na partida, por quem e quando.

## Esperado
Uma seção "Histórico da partida" na página da partida (Admin e Gestor), do mais recente ao mais antigo, com data e hora, uma frase em português por alteração e o autor.

## Atual
A página tinha placar, lances, linha do tempo e legenda, sem histórico (`docs/checkpoints/ux-audit/before-0112/`).

## Correção
- **`MatchHistory`** (`app/forms/match_history.rb`): os 100 registros de auditoria mais recentes da partida, com o autor carregado junto, e os nomes dos jogadores citados (uma consulta só).
- **`MatchHistoryHelper#match_history_text`**, uma frase por ação:
  - `cartola.scout_event_recorded` / `cartola.scout_event_undone`: "Lance registrado: Gol · Felipe Santos · 32' · 1º tempo" / "Lance desfeito: …";
  - `cartola.participation_marked`: "Jogou marcado: …", "Destaque desmarcado: …";
  - `finalize`: "Partida finalizada em 2 × 1 e pontuada" (as finalizações anteriores ao TICKET-0110, sem pontuação na hora, ficam "Partida finalizada em 2 × 1");
  - `rescore`: "Placar e pontos refeitos: 3 × 1 → 3 × 2", ou "Pontos refeitos, placar mantido em 3 × 1" quando só os pontos mudam;
  - `revert`: "Pontuação revertida. Motivo: …";
  - `match.rescheduled`: "Partida remarcada para 20/12 16:00. Motivo: …";
  - `cartola.scouts_recorded`: "Estatísticas registradas pela ficha";
  - qualquer outra ação: "Alteração na partida".
- **`match_history_author`:** o nome do usuário, senão o e-mail, senão "Sistema".
- **`admin/match_board/_history`:** seção "Histórico da partida" abaixo da legenda, no Admin e no Gestor, com `<time datetime>` e "Nada feito nesta partida ainda." quando vazia.

## Evidência
- Specs:
  - `spec/helpers/match_history_helper_spec.rb`: a frase de cada ação, o placar antes e depois, o motivo, a remarcação, a frase genérica e o autor;
  - `spec/requests/match_history_spec.rb`: no Gestor, lance, finalização e lance depois de pontuada aparecem do mais recente ao mais antigo com o autor; no Admin, a seção vazia.
- Navegador (partida 387, depois das edições do TICKET-0111): a seção lista "Lance registrado: Gol · Felipe Santos · 1º tempo", "Placar e pontos refeitos: 3 × 1 → 3 × 2", os desfazeres até "3 × 2 → 3 × 1", "Destaque marcado: Igor Carvalho" e "Pontos refeitos, placar mantido em 3 × 1", com "Gestor Demo" e "Administrador" como autores.
- Screenshots: `docs/checkpoints/ux-audit/before-0112/` e `after-0112/` (página do Gestor e do Admin, recorte da seção `gestor-historico-1440.png`).

## Pronto quando
- [x] Seção "Histórico da partida" na página da partida do Admin e do Gestor
- [x] Uma frase em português por alteração (lances, participação, finalização, placar antes → depois, reversão com motivo, remarcação), com autor e data
- [x] Do mais recente ao mais antigo, sem consultas por linha
