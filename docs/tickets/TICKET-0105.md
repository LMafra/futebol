# TICKET-0105 — Público: partidas por rodada e carrossel "Jogos de hoje" com avanço automático

- Deps: TICKET-0103
- Skill: [W]tdd
- MCP: playwright
- Origem: rodada de ajustes de 2026-11-12 (grill de listagens)

## Descrição
- **Aba Partidas** (`/campeonatos/:id?tab=partidas`):
  - mostrava uma rodada por vez. Ver outra rodada exigia andar rodada a rodada pelos botões "Rodada N";
  - a lista era diferente da do Admin e do Gestor;
  - a partida em andamento aparecia só como "Ao vivo" em letra miúda, sem dizer que a linha leva à página ao vivo.
- **"Jogos de hoje"** (home): a faixa só andava pelos botões ou pelo arrasto. Num dia com muitos jogos, quem não mexia via só os primeiros.

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração (cinco partidas do Brasileirão movidas para hoje)
- Visitante sem login

## Severidade
Baixa: tudo era alcançável, mas exigia passos a mais.

## Passos para reproduzir
1. Abrir `/campeonatos/1?tab=partidas` em 390px.
2. Procurar a rodada 2.
3. Abrir a home num dia com cinco jogos e esperar.

## Esperado
- Todas as rodadas numa lista, com a rodada atual aberta e as outras a um toque.
- O carrossel anda sozinho e para quando a pessoa interage.

## Atual
- Uma rodada por vez (`docs/checkpoints/ux-audit/before-0105/public-partidas-390.png`).
- O carrossel parado no primeiro jogo (`before-0105/home-today-390.png`).

## Correção
- **Aba Partidas:** `Ui::CollectionComponent` no modo `grouped`, o mesmo das partidas do Admin e do Gestor.
  - Uma sanfona por rodada, mais "Sem rodada" no fim.
  - Abre a primeira rodada com partida agendada ou ao vivo. Sem nenhuma, abre a última. `?rodada=N` abre outra.
  - Cada linha leva à página da partida. A partida ao vivo tem o selo "Ao vivo" e o rótulo acessível "acompanhar ao vivo".
- **Carrossel** (`scroller_controller.js`, valor `autoplay` em ms; a home usa 6000):
  - avança um jogo a cada 6s, só quando os jogos não cabem na tela;
  - mouse ou foco dentro seguram o avanço até saírem;
  - um toque ou o botão "Pausar" param até "Continuar";
  - com "reduzir movimento" no sistema, não avança sozinho e o botão some;
  - "anterior" e "próximo" reiniciam a contagem.

## Evidência
- `spec/requests/championships_spec.rb`:
  - rodadas em sanfona, com a rodada em aberto aberta;
  - link e rótulo da partida ao vivo;
  - `?rodada=`;
  - última rodada quando todas estão encerradas, e "Sem rodada".
- `spec/requests/home_spec.rb`: avanço a cada 6s, eventos de pausa e botão.
- `spec/requests/matches_spec.rb`: a linha da aba Partidas leva à página da partida.
- Playwright (`tmp/pw/carousel0105.js`, 390px):
  - avança sozinho;
  - mouse em cima segura;
  - "Pausar" para e vira "Continuar";
  - "Continuar" volta a avançar;
  - toque para;
  - com "reduzir movimento", sem botão.
- Screenshots: `docs/checkpoints/ux-audit/before-0105/` e `after-0105/`.

## Pronto quando
- [x] Aba Partidas por rodada com o componente, rodada atual aberta e link para a página ao vivo
- [x] Carrossel com avanço a cada ~6s, pausa por mouse, foco e toque, botão Pausar/Continuar e "reduzir movimento"
- [x] Screenshots antes e depois
