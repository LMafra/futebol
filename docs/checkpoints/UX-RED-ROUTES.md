# UX Red Routes — Admin e Gestor (TICKET-0078)

Protocolo formativo para as três tarefas críticas do Admin e do Gestor. Mede-se o mesmo conjunto por tarefa:
- sucesso
- tempo na tarefa
- cliques contra o caminho ideal
- erros
- SEQ (Single Ease Question, 1–7)

Não é teste A/B em produção. Esta é **uma passagem interna**, feita pelo agente com Playwright no ambiente local, depois de 0074–0077 e 0079–0084.

## Como moderar (sessão com pessoa)

1. Ambiente local com dados de demonstração (`bin/dev`, Postgres na porta 5440), 1440px. Antes de cada sessão, garantir:
   - 1 usuário com `manager_status: pending`
   - 1 partida `live` sem scouts num campeonato do gestor
2. Ler a tarefa em voz alta, sem citar nomes de botões ou menus. Começar a cronometrar no primeiro movimento, já logado no painel (`/admin` ou `/gestor`).
3. Contar como clique:
   - cada clique em link ou botão
   - cada aceite de `confirm`
   - cada navegação feita pela pessoa (voltar ou digitar URL)

   Digitação é registrada à parte.
4. Conta como erro:
   - clique num caminho que não leva à tarefa
   - envio rejeitado por validação
   - pedido de ajuda
5. Ao final de cada tarefa, perguntar: "No geral, quão fácil ou difícil foi esta tarefa?" (1 = muito difícil, 7 = muito fácil).
6. Sucesso = o estado final esperado está no banco e a tela confirma (flash ou redirecionamento).

## Cenários e caminho ideal

| # | Persona | Tarefa | Caminho ideal | Cliques ideais |
|---|---|---|---|---|
| 1 | Admin | Aprovar o gestor pendente mais antigo | Painel → fila "Gestores pendentes" → **Aprovar** na linha | 1 |
| 2 | Gestor | Lançar os scouts de uma partida ao vivo e finalizá-la | Painel → fila de partidas → **Lançar scouts** → `+` num scout → **Salvar scouts** → Painel → **Finalizar** → digitar o placar (`1x0`) → **Finalizar partida** | 6 |
| 3 | Gestor | Criar um campeonato só com o obrigatório | Painel → **Novo campeonato** → Nome (e temporada, se vazia) → **Continuar** ×3 → **Criar** | 5 |

## Resultado da passagem interna (2026-11-12)

Script Playwright local (fora do repositório), com fixtures temporárias criadas e removidas via `bin/rails runner`. Os tempos são da automação, não de uma pessoa. Servem para comparar caminhos, não como referência humana.

| # | Sucesso | Tempo (automação) | Cliques / ideal | Digitação | Erros | SEQ (estimativa) |
|---|---|---|---|---|---|---|
| 1 | sim | 1,3 s | 1 / 1 | — | 0 | 7 |
| 2 | sim | 3,9 s | 6 / 6 | 3 caracteres | 0 | 5 |
| 3 | sim | 1,5 s | 5 / 5 | 18 caracteres | 0 | 6 |

Notas:
1. **Aprovar gestor.** A ação é inline na fila (0075) e funciona sem Turbo (0079). Não há página intermediária nem `confirm`. Antes, o caminho passava por Usuários → perfil → Aprovar. O botão fazia GET numa rota PUT e a tarefa **falhava**: [TICKET-0079](../tickets/TICKET-0079.md).
2. **Scouts e finalizar.** A fila escolhe o próximo passo certo (0076): "Lançar scouts" e depois "Finalizar". O único custo extra é voltar ao Painel depois de salvar os scouts, porque a página de scouts não oferece o próximo passo. Por isso o SEQ estimado é 5. Antes, o painel mostrava "Finalizar" até em partidas agendadas e um atalho "Scouts" sem partida (ver `ux-audit/before/gestor-dashboard-1440.png`).
3. **Criar campeonato.** O wizard (0077) troca uma página longa de quatro seções por quatro etapas. São 3 cliques a mais ("Continuar"), mas cada tela mostra só um grupo de campos e o envio fica na última etapa. As etapas 2–4 já vêm com os padrões.

## Follow-ups sugeridos (fora do escopo)

- Na página de scouts, depois de salvar com scouts lançados, oferecer **Finalizar partida** como próximo passo. Isso tira a volta ao Painel do cenário 2 (6 → 5 cliques).
- Repetir os três cenários com 3–5 pessoas (organizadores reais) e registrar o SEQ medido nesta tabela.

## Evidência visual

- `docs/checkpoints/ux-audit/before/` e `docs/checkpoints/ux-audit/after/`:
  - mesmas telas em 1440px e 390px;
  - seis telas do Admin em modo escuro do sistema (`-dark`);
  - `probe.json` com status, classe `.dark` e textos de baixo contraste por tela.
- Depois:
  - todas as telas respondem 200;
  - nenhuma ganha `.dark` com o sistema escuro;
  - o público zera os alertas de contraste, exceto os tints de 15% de palpites e bolão.
- Os alertas restantes no Admin são falsos positivos: o probe não lê o alpha de fundos `oklab(... / 0.15)`. Isso cobre o item de menu ativo e os scopes com `bg-cartola/15`, e os `−`/`+` desabilitados dos scouts.
