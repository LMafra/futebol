# TICKET-0083 — Consistência pública: botões, tabelas, ARIA de abas/erros/progresso, estados e detalhes

- Deps: TICKET-0082
- Skill: [W]tdd, ui-ux-pro-max
- MCP: —
- Origem: auditoria UI/UX completa (2026-11-12)

## Descrição
As telas públicas tinham pelo menos cinco receitas de botão para o mesmo papel:
- verde `bg-pitch`
- `bg-cartola` com hover `pitch`
- `bg-cartola` com hover `ink`
- borda `ink` simples
- borda `ink` dupla

Os pesos de fonte variavam e as ações destrutivas ("Excluir bolão", "Desfazer escalação") eram sublinhados cinza.

Nas tabelas:
- O cabeçalho mudava de componente para componente: `pitch` sólido, texto `graphite` e borda `ink`.
- Nenhuma rolava na horizontal em 390px.
- Os glifos V/E/D e ▲/▼ dependiam de `aria-label` em `span`, que leitores de tela ignoram.

Na acessibilidade:
- As abas eram links com `role="tab"` e `aria-selected`, sem o padrão de teclado de abas.
- Erros de palpite e de bolão não ficavam ligados ao campo.
- A barra de orçamento não tinha nome nem valor legível.
- "Copiada!" não era anunciado.

Nos estados:
- Empty, erro e flash tinham raios e paddings próprios em cada tela.

## Ambiente
- Desktop 1440px e mobile 390px, Chromium 1208 (Playwright), Rails 8.1 dev local
- Usuários: visitante e `demo1@demo.local`

## Severidade
Média: nada bloqueava o uso, mas a hierarquia de ações era incoerente e vários estados não chegavam a quem usa leitor de tela.

## Passos para reproduzir
1. Comparar "Entrar" (`/entrar`), "Criar bolão" (`/pools`), "Palpitar" (`/pools/:id/bets`) e "Projetar tabela" (`/simulador/:id`).
2. Abrir `/campeonatos/:id` e `/esquadrao/rankings` e inspecionar as abas.
3. Em 390px, abrir `/pools/:id/bets` e ver a tabela "Meus palpites" cortada.
4. Enviar um palpite inválido e inspecionar o campo.

## Esperado
- Três papéis de botão (primary, secondary, danger) iguais em todas as telas.
- Tabelas com o mesmo cabeçalho e rolagem própria.
- Abas como navegação com `aria-current="page"`.
- Erros ligados aos campos.
- Estados com um só visual.

## Atual
- Cada tela tem sua receita.
- As tabelas estouram a largura.
- Leitores de tela anunciam "tab" sem o comportamento de abas.
- Os erros ficam soltos.

## Correção
- **Botões.** `ButtonClassesHelper` com `primary_button_classes`, `secondary_button_classes` e `danger_button_classes`:
  - Base comum: 48px, `font-bold`, transição e `disabled:` legível. Tamanhos `sm`, `md` e `lg`.
  - Primary `bg-cartola text-ink`; secondary `border-graphite bg-white`; danger `bg-loss-solid text-white` (`loss-solid` entra no config público).
  - Aplicado em entrar, senha, conta, pedido de gestor, cadastro, bolões, palpite, escalação, simulador, hero, campeonatos, rankings e 403.
  - Os botões verdes viram primary. "Excluir bolão" e "Desfazer escalação" viram danger.
- **Tabelas.** Standings, Leaderboard, `Cartola::RankingTable` e MyBets:
  - Cabeçalho `bg-pitch text-paper` e wrapper `overflow-x-auto` (`data-role="table-scroll"`).
  - MyBets e RankingTable com cantos arredondados no wrapper e `scope="col"`.
  - V/E/D e ▲/▼ como glifo `aria-hidden` mais texto `sr-only`.
- **ARIA**
  - Abas de campeonato e de rankings sem `role=tab`, `role=tablist` e `aria-selected`; a aba atual tem `aria-current="page"` (`tab_link_classes`).
  - Palpite, novo bolão e "Entrar com código" com `aria-invalid` e `aria-describedby` apontando para a mensagem; o campo usa a variante `invalid:`.
  - Barra de orçamento com `aria-label="Orçamento usado"`, `aria-valuetext` em reais, `aria-valuenow` limitado ao máximo e trilho `bg-graphite/30`.
  - "Copiar chave" anuncia "Chave Pix copiada." numa região `aria-live="polite"`.
- **Estados.** `StateNoticeHelper` (`empty_notice`, `error_classes`), incluído no `Ui::BaseComponent` e disponível nas views:
  - Aplicado no simulador (erros, sem jogos, limite de projeções), `_partidas`, índice do simulador, campeonatos e jogos de hoje da home.
  - Flash público com `rounded-md p-4`, igual ao toast do Admin.
- **Detalhes**
  - "Meus palpites" e "Jogos abertos" com `font-extrabold`, como os títulos das páginas.
  - 403 com o cabeçalho padrão: sobretítulo, `h1` 4xl e filete `ink`.
  - Setas de rodada em SVG, como botões secondary (`round_nav_link`, `rel=prev/next`), no Esquadrão e em Partidas.
  - `<summary>` de "Minha conta" e "Pague o Café" com chevron que gira ao abrir e sem o marcador do WebKit.
  - Card de "Jogos de hoje" inteiro clicável; ao vivo com borda `cartola` e chip `bg-cartola text-ink`.
  - Hovers `hover:bg-paper` viram `hover:bg-rule` / `hover:border-ink`.
  - Links do rodapé com uma só classe.

## Evidência
- Navegador (Playwright), 1440px e 390px. Em campeonato, Esquadrão, bolão, palpites e home:
  - os botões têm o mesmo formato por papel e "Excluir bolão" aparece como danger;
  - as tabelas têm cabeçalho `pitch` e "Meus palpites" rola dentro do wrapper em 390px.
- O probe de contraste não mudou em relação ao 0082. Os únicos alertas são os tints de 15%, que o probe lê como cor sólida.
- Specs:
  - `spec/helpers/button_classes_helper_spec.rb`;
  - componentes Standings (wrapper e `sr-only`), RankingTable, MyBets, Leaderboard, BudgetBar (ARIA), Prediction e Pools (`aria-invalid`/`aria-describedby`, danger);
  - requests de campeonato (`aria-current`, sem `role=tab`, seta SVG), rankings, home (card clicável e ao vivo) e layout (rodapé e `aria-live`).

## Pronto quando
- Nenhum botão público fora dos três papéis
- Tabelas com wrapper de rolagem
- Abas sem `role=tab`
- Gate `test` verde
