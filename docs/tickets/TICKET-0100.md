# TICKET-0100 — Participantes › Esquadrão: ranking, gabarito da rodada e edição de escalação com motivo

- Deps: TICKET-0094, TICKET-0099, TICKET-0102
- Skill: [W]tdd
- MCP: playwright (Gestor em 390px)
- Origem: rodada de ajustes de 2026-11-12 (fase 5, participantes), ADR 0006

## Descrição
- **Telas espalhadas:** o Esquadrão aparecia em duas telas que não conversavam.
  - No Admin, "Rankings do Esquadrão" mostrava pontos e moedas.
  - No Gestor, "Escalações do Esquadrão" era uma lista de escalações sem pontos.
- **Sem gabarito:** nenhuma das duas mostrava os pontos de cada jogador real na rodada nem a melhor escalação possível.
- **Sem correção:** o organizador não tinha como corrigir uma escalação.

## Ambiente
- Rails 8.1, ActiveAdmin 4 (`/admin/esquadrao` e `/gestor/esquadrao`)
- Chromium 1208 (Playwright) em 390×844, como gestor@demo.local

## Severidade
Média: o organizador não conseguia conferir a rodada nem atender um pedido de correção de escalação.

## Passos para reproduzir
1. Entrar como gestor e abrir Participantes › Escalações do Esquadrão.
2. Procurar os pontos da rodada e quem pontuou.
3. Tentar corrigir a escalação de um participante.

## Esperado
- Ranking do campeonato.
- Gabarito da rodada: pontos por jogador real e a seleção ideal.
- Escalações com os pontos de cada jogador.
- Editar a escalação (jogadores, capitão, formação) com motivo, auditoria e recálculo.

## Atual
Uma lista de escalações sem pontos e, só no Admin, o ranking numa tela separada.

## Correção
- **Uma página, Participantes › Esquadrão** (`app/admin/esquadrao.rb`, `EsquadraoBoard`, `admin/esquadrao/*`), igual no Admin e no Gestor:
  - escolhe campeonato e rodada (`?championship_id=`, `?rodada=`). A rodada padrão é a última pontuada. O Gestor só vê os seus campeonatos.
  - **Ranking do campeonato:** pontos (`Cartola::RankingsService`, capitão em dobro, empate divide a posição) e moedas de cada participante.
  - **Gabarito da rodada:**
    - pontos por jogador real, numa lista recolhível;
    - seleção ideal: os melhores jogadores com pontos positivos por posição, em cada formação limitada pelo campeonato. O capitão é o melhor deles e o total conta o capitão em dobro.
  - **Escalações da rodada:** lista com detalhe (`Ui::CollectionComponent`, `master_detail`, `?escalacao=ID`). O detalhe mostra a escalação no campinho (`Cartola::PitchComponent` com `points:`), com os pontos de cada jogador (capitão em dobro) e o total.
- **Editar escalação** (`?editar=1`, `Cartola::LineupCorrection`, `LineupCorrectionForm`):
  - formação, jogadores por posição, capitão e motivo obrigatório;
  - passa por `Cartola::WalletService`, como a troca feita pelo próprio participante: a carteira paga ou recebe a diferença de preço e continua batendo com os jogadores escalados;
  - o ranking lê a escalação, então os pontos mudam na hora (recálculo);
  - `AuditLog` `esquadrao.lineup_corrected` com antes, depois, rodada e motivo;
  - com erro, volta ao formulário preenchido, com o alerta e o foco no motivo.
- **Quem pode:**
  - no Admin, o Admin;
  - no Gestor, quem gerencia o campeonato (`Cartola::LineupPolicy#correct?`, `PagePolicy#update_lineup?`).
- **Menu e endereços:**
  - Participantes passa a ter Bolões, Esquadrão, Times do Esquadrão (Admin) e Usuários (Admin);
  - "Jogadores" já estava em Times desde a TICKET-0094;
  - `/admin/esquadraorankings`, `/admin/cartolarankings` e `/gestor/esquadrao_lineups/*` redirecionam para a página nova;
  - o botão do campeonato passa a se chamar "Esquadrão".

## Evidência
- `spec/requests/admin/esquadrao_spec.rb`:
  - ranking;
  - seleção ideal com capitão, sem jogador negativo;
  - pontos por jogador;
  - detalhe da escalação;
  - correção com auditoria e ranking atualizado;
  - sem motivo, volta ao formulário preenchido;
  - o Gestor corrige no seu campeonato e não alcança o de outro;
  - redirecionamento da URL antiga.
- `spec/requests/admin/cartola_settings_spec.rb` e `spec/requests/admin/navigation_spec.rb`: ranking com moedas, link do campeonato, redirecionamentos e menu.
- Playwright (`tmp/pw/esquadrao0100.js`, 390px):
  - ranking, gabarito e escalações, sem rolagem lateral;
  - detalhe com os pontos;
  - enviar sem motivo volta ao formulário com o alerta e o foco no motivo.

## Pronto quando
- [x] Usuários, ranking e gabarito da rodada (pontos por jogador real + seleção ideal)
- [x] Editar escalação (jogadores, capitão, formação), com motivo + `AuditLog` + recálculo
- [x] "Jogadores" fora de Participantes, em Times
