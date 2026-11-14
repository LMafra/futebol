# TICKET-0108 — Moeda E$ no lugar de C$

- Deps: TICKET-0107
- Skill: [W]tdd
- MCP: playwright
- Origem: revisão do PR #87 (2026-11-14)

## Descrição
Os valores do Esquadrão apareciam como "C$" e cada tela formatava o próprio valor (`format('C$ %.2f', ...)` repetido em componentes, páginas do Admin e do Gestor, controller, serviço e `lib/`). A moeda do produto é E$ (Esquadrão).

## Ambiente
- Celular 390px e desktop 1440px, Chromium 1208 (Playwright), dados de demonstração
- Gestor (`gestor@demo.local`) e Admin (`admin@futebol.dev`)

## Severidade
Baixa: os valores estavam certos, só o símbolo e a formatação espalhada.

## Passos para reproduzir
1. Entrar como gestor e abrir `/gestor/players`.
2. Ler a coluna "Valor base" e o rótulo "Valor base (C$)" do formulário.
3. Abrir a escalação do Esquadrão e ler o orçamento ("Gasto C$ ... de C$ ...").

## Esperado
"E$" em todo valor do Esquadrão, vindo de um formatador só.

## Atual
"C$" em toda a interface (`docs/checkpoints/ux-audit/before-0108/`).

## Correção
- **Formatador único:** `Cartola::Money` no engine `cartola`, com `SYMBOL = 'E$'`, `format(value)` ("E$ 12.50") e `label(text)` para os campos de formulário ("Valor base (E$)"). Nas views e componentes, o helper `esquadrao_money(value)` (`EsquadraoMoneyHelper`) delega a ele. O formatador fica no engine porque o `WalletService` também mostra valores e o Packwerk não deixa o engine depender de helpers do app.
- **Pontos trocados:**
  - barra de orçamento, campo, seletor de jogadores e classificação de moedas;
  - mensagens de saldo insuficiente e de escalação desfeita;
  - resumo do campeonato, formulário e página do campeonato no Admin e no Gestor;
  - valor base dos jogadores na listagem, no time e no modal (rótulos com `Cartola::Money.label`);
  - página do Esquadrão no Admin (moedas por participante);
  - comentário de `db/seeds/players.rb` e todos os specs.
- **ADR 0005:** não editada. Ela registra a fórmula de valorização com valores em "C$"; os números continuam válidos, e a partir deste ticket o símbolo da moeda é E$.
- **Glossário:** entrada E$ (_Avoid_: C$, R$, cartoletas).

## Evidência
- `spec/helpers/esquadrao_money_helper_spec.rb`: "E$ 12.50" e a delegação a `Cartola::Money`.
- `spec/design/esquadrao_money_spec.rb`:
  - falha se "C$" voltar a `app`, engines, `lib`, locales ou seeds;
  - falha se alguém formatar "E$" fora de `Cartola::Money`.
- Specs atualizados: barra de orçamento, campo, classificação, escalações, valorização e configurações do Esquadrão.
- Screenshots: `docs/checkpoints/ux-audit/before-0108/` e `after-0108/`.

## Pronto quando
- [x] E$ em todo valor do Esquadrão
- [x] Um formatador só (`Cartola::Money`, `esquadrao_money` nas views)
- [x] Nenhum C$ em app, engines, lib, seeds e specs
- [x] ADR 0005 intacta, troca registrada aqui
