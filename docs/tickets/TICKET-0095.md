# TICKET-0095 — Cadastros em diálogo: time, jogador, partida, inscrição e bolão

- Deps: TICKET-0094
- Skill: [W]tdd
- MCP: —
- Origem: rodada de ajustes de 2026-11-12 (grill do Gestor)

## Descrição
- **Saída da página:** cadastrar um jogador a partir da página do time levava para outra tela e, no fim, para a página do jogador, longe do time.
- O mesmo acontecia com a partida e o bolão criados a partir do campeonato.
- **Inscrição sem foco:** a inscrição de times era um formulário solto no meio do painel.
- **Erro sem volta:** quando a validação falhava, o Gestor ficava na tela cheia de cadastro, sem o caminho de volta.

## Ambiente
- Celular 390px, Chromium 1208 (Playwright), `/gestor` com o gestor de demonstração

## Severidade
Média: os cadastros mais frequentes do Gestor tiravam ele do contexto a cada item.

## Passos para reproduzir
1. Entrar como gestor e abrir um time em `/gestor/teams/:id`.
2. Clicar em "Cadastrar jogador" e salvar.
3. Repetir para o próximo jogador.

## Esperado
O cadastro abre por cima da página do time e, salvo, volta para ela com o aviso. Com erro, o diálogo reabre com os erros e o que foi digitado.

## Atual
Cada jogador passava por duas telas: o cadastro e a página do jogador.

## Correção
- **Diálogos com `<dialog>`** (`ModalFormHelper` + `modal_controller.js`):
  - **Novo time:** na lista de times.
  - **Cadastrar jogador:** na página do time, já com o time.
  - **Agendar partida:** na página do campeonato do Gestor, só com os times inscritos.
  - **Inscrever time:** no painel de inscritos.
  - **Criar bolão:** na página do campeonato.
- **Abertura:**
  - O botão é um link para a tela cheia de cadastro; sem JavaScript, ele simplesmente navega.
  - Com JavaScript, abre o diálogo com foco no primeiro campo.
  - Esc, "Cancelar" ou um clique fora fecham o diálogo.
- **Depois de salvar** (`ModalFormResponses`): volta para a página de origem com o aviso ("Jogador cadastrado: …", "Bolão criado. Compartilhe o código …").
- **Com erro** (`ModalFormRedirects`):
  - volta com `?modal=<id>`, e o flash leva os erros e os valores digitados;
  - o diálogo reabre com o resumo dos erros, os campos marcados (`aria-invalid`) e o foco no primeiro campo com erro;
  - o escudo não volta e precisa ser escolhido de novo.
- `?modal=<id>` também abre o diálogo direto, inclusive sem JavaScript (renderizado aberto, na página).
- `return_to` só é aceito dentro do namespace atual.

## Evidência
- `spec/requests/gestor/modal_forms_spec.rb`: abertura, volta depois de salvar, reabertura com erros e valores, `return_to` fora do namespace, partida, inscrição, time e bolão
- Playwright 390px: abrir e fechar com Esc, erro com reabertura e foco no campo inválido, sucesso com aviso; diálogos de time, jogador, bolão e inscrição

## Pronto quando
- [x] Cinco cadastros em diálogo, com a tela cheia como alternativa sem JavaScript
- [x] Salvo, volta para a página de origem com aviso
- [x] Com erro, reabre com `?modal=` mostrando os erros e os valores digitados
