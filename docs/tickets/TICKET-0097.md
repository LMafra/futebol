# TICKET-0097 — Tela única da partida no Admin e no Gestor

- Deps: TICKET-0095, TICKET-0096
- Skill: [W]tdd
- MCP: playwright (revisão em 390px)
- Origem: rodada de ajustes de 2026-11-12 (grill da partida ao vivo), ADR 0006

## Descrição
- **Três telas:** registrar uma partida ao vivo passava por três telas: a da partida, a planilha de scouts (`matchscouts`) e a de finalização (`matchfinalizer`).
- **Planilha no celular:** a planilha era uma tabela larga, com contadores de 40px e rolagem lateral. No celular, à beira do campo, era difícil de usar.
- **Sem minuto nem linha do tempo:** a planilha não registrava minuto nem tempo, e a partida não mostrava os lances em ordem.

## Ambiente
- Rails 8.1, ActiveAdmin 4 beta23, Chromium 1208 (Playwright) em 390×844
- Admin (admin@futebol.dev) e Gestor (gestor@demo.local)

## Severidade
Alta: é a tela usada durante a partida, quase sempre no celular.

## Passos para reproduzir
1. Abrir uma partida ao vivo em `/gestor/matches/:id`, em 390px.
2. Tocar em "Scouts" e lançar um gol do mandante.
3. Voltar e tocar em "Finalizar".

## Esperado
Uma tela só, com:
- placar grande;
- um botão grande por jogador e estatística, que abre o diálogo de tempo e minuto;
- linha do tempo e legenda;
- "Finalizar" no rodapé fixo.

## Atual
Eram três telas. A planilha só aceitava totais e, em 390px, precisava de rolagem lateral.

## Correção
- **Página da partida** (`AdminMatchBoard`, `admin/match_board/*`, `MatchBoard`), igual no Admin e no Gestor:
  - **placar grande**: escudos, status, campeonato, rodada e data;
  - **abas Mandante e Visitante** (`tabs_controller.js`):
    - ARIA com setas, Home e End;
    - a aba escolhida continua após registrar um lance;
    - sem JavaScript, os dois times aparecem;
  - **cartão por jogador** (goleiro primeiro), com:
    - um botão "+" por estatística (DE só para goleiro);
    - os totais com "−", que desfaz o último lance daquela estatística;
    - "Jogou" e "Destaque" (`aria-pressed`);
  - **linha do tempo**: os lances mantidos, do mais recente ao mais antigo;
  - **legenda** recolhida.
- **Diálogo do lance** (`modal_form :lance`):
  - o botão "+" preenche jogador, estatística e título (`data-modal-values` no `modal_controller.js`);
  - o tempo vem preenchido com o do último lance;
  - o minuto é opcional e recebe o foco;
  - sem JavaScript, o link abre o diálogo pela URL;
  - lance recusado volta ao diálogo com o erro e o que foi escolhido.
- **Rodapé fixo com "Finalizar partida":**
  - mostra o placar dos lances;
  - o diálogo pede a confirmação do placar (`MatchFinalizationForm`);
  - com erro, volta ao diálogo; o Admin também tem o link para o Preview do Bolão;
  - sem lances, o rodapé mostra só o aviso, sem o botão.
- **Ações da partida** (`record_event`, `undo_event`, `participation`, `finalize`):
  - autorizadas por `record_event?`, `undo_event?` e `participation?`, que seguem `record_scouts?`, e por `finalize?` na política da partida;
  - usam `Scouts::RecordEvent`, `Scouts::UndoLast` e `MatchFinalizationForm`;
  - "Jogou" e "Destaque" usam o novo `Scouts::MarkParticipation`:
    - um destaque por partida; destaque conta como jogou;
    - o jogador sem lance que não jogou sai da partida;
    - SG e pontos são recalculados.
- **Páginas antigas:** `matchscouts` redireciona para a partida, e `matchfinalizer` para a partida com `?modal=finalize`. Painel do Admin, Preview do Bolão e fila do Gestor apontam para a partida.
- **Removidos:** a planilha (`MatchScoutSheet`, `scouts_controller.js`, `admin/match_scouts/_form`), a tela de finalização e os botões "Scouts" e "Finalizar" do cabeçalho. "Reverter pontuação" continua.

## Evidência
- `spec/requests/admin/match_board_spec.rb`:
  - placar, abas, botões e diálogo pela URL;
  - lance com tempo e minuto, lance recusado, desfazer;
  - "Jogou" e "Destaque";
  - finalizar com erro e com sucesso;
  - partida pontuada só para leitura;
  - redirecionamentos e 403.
- `spec/requests/gestor/scoring_spec.rb`: Gestor só nas próprias partidas, finalizar, reverter e redirecionamentos.
- `spec/system/admin_finalizes_match_spec.rb`: três gols pelo diálogo, troca de aba, finalização e pontuação dos palpites (Chromium).
- `spec/requests/admin/accessibility_spec.rb` e `consistency_spec.rb`: abas ARIA, rótulos dos botões e confirmação com `aria-invalid`.
- Playwright em 390px (`tmp/pw/board0097.js`):
  - sem rolagem lateral;
  - diálogo modal com o título do jogador e o foco no minuto;
  - lance e desfazer com aviso;
  - a aba Visitante continua após recarregar.

## Pronto quando
- [x] Placar grande, abas por time e botões grandes por jogador que abrem o diálogo de tempo e minuto
- [x] Linha do tempo, legenda e "Finalizar" no rodapé fixo
- [x] `matchscouts` e `matchfinalizer` redirecionam; "Reverter" mantido
