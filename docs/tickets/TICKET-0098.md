# TICKET-0098 — Página pública da partida ao vivo

- Deps: TICKET-0096, TICKET-0097
- Skill: [W]tdd
- MCP: playwright (atualização ao vivo em 390px)
- Origem: rodada de ajustes de 2026-11-12 (grill da partida ao vivo), ADR 0006

## Descrição
- **Sem página da partida:** o público não tinha página da partida. Os jogos de hoje levavam ao campeonato, e a aba Partidas só listava os placares.
- **Broadcast sem destino:** `BroadcastUpdateService` transmitia o placar, mas nenhuma página assinava o stream.
- **Visitante rejeitado:** a conexão do ActionCable rejeitava quem não tinha sessão.
- **Último lance perdido:** a janela de 5 segundos descartava o último lance de uma sequência rápida.

## Ambiente
- Rails 8.1, Turbo 8 (`turbo_stream_from`), ActionCable (async no desenvolvimento, Solid Cable em produção)
- Chromium 1208 (Playwright): um visitante em 390×844 e o Admin lançando em outra sessão

## Severidade
Média: quem acompanha de fora não via a partida ao vivo.

## Passos para reproduzir
1. Abrir a home como visitante e tocar num jogo de hoje.
2. Em outra sessão, registrar um gol nessa partida.
3. Voltar à primeira aba.

## Esperado
Uma página da partida com placar grande e linha do tempo. O gol aparece sem recarregar.

## Atual
O jogo abria o campeonato, e nada se atualizava.

## Correção
- **`/partidas/:id`** (`MatchesController#show`, `matches/show`, `matches/_live`):
  - placar grande (`Ui::ScoreboardComponent`, agora em duas linhas no celular);
  - gols por time, com minuto e "(GC)";
  - linha do tempo dos lances mantidos, do mais recente ao mais antigo (`Cartola::ScoutEvent.timeline`);
  - link de volta para a rodada do campeonato.
- **Quem vê** (`Core::MatchPolicy#public_show?`):
  - campeonatos publicados;
  - num campeonato privado, só quem participa de um bolão dele, o gestor e o Admin;
  - nos outros casos, 404.
- **Ao vivo:**
  - a página assina `turbo_stream_from @match`;
  - `BroadcastUpdateService` troca o bloco do placar e da linha do tempo; lance, desfazer, Jogou/Destaque, finalização, pontuação e reversão transmitem;
  - na janela de 5 segundos, as chamadas descartadas agendam uma única transmissão no fim (`MatchBroadcastJob`), com o estado de então.
- **ActionCable:** a conexão aceita visitante sem sessão. O único canal, `Turbo::StreamsChannel`, só aceita os nomes de stream assinados pelas páginas.
- **Links para a partida:** card dos jogos de hoje na home, linha da aba Partidas do campeonato, jogos abertos e "Meus palpites" do bolão (`MatchLinksHelper#match_title`).

## Evidência
- `spec/requests/matches_spec.rb`:
  - placar, gols com GC, linha do tempo e stream assinado;
  - partida agendada;
  - 404 para rascunho e para privado;
  - acesso de participante de bolão;
  - links da aba Partidas e da home.
- `spec/services/matches/broadcast_spec.rb`:
  - replace do bloco ao vivo;
  - uma transmissão agendada para as descartadas, com o estado atual;
  - finalização transmite.
- `spec/channels/application_cable/connection_spec.rb`: visitante e usuário com sessão.
- Playwright (`tmp/pw/live0098.js`):
  - o visitante em 390px vê o placar ir de 0×0 a 1×0 e o lance na linha do tempo, sem recarregar, depois do gol lançado pelo Admin;
  - depois do desfazer, volta a 0×0;
  - sem rolagem lateral.

## Pronto quando
- [x] Placar grande e linha do tempo em `/partidas/:id`
- [x] `turbo_stream_from match` com broadcast nos serviços de lance, finalização e reversão
- [x] Links a partir da home, do campeonato e dos palpites
